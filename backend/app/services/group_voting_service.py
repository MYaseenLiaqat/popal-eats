"""Group recommendation snapshots, voting, and consensus decisions."""

from __future__ import annotations

import logging
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.models.group_decision import (
    AGREED,
    CONSIDERING,
    ORDERED,
    PENDING,
    GroupDecision,
)
from app.models.group_recommendation import GroupRecommendation
from app.models.group_session_member import GroupSessionMember
from app.models.group_vote import GroupVote
from app.schemas.group_recommendation import GroupDishRecommendation, GroupRecommendationsResponse
from app.schemas.group_voting import (
    GroupDecisionResponse,
    GroupVoteResponse,
    GroupVoteSummaryResponse,
)
from app.services.group_recommendation.consensus import (
    compute_consensus_score,
    compute_final_score,
    count_positive_voters,
    should_mark_agreed,
    summarize_votes,
)
from app.services.group_recommendation_service import get_group_recommendations
from app.services.group_session_service import _get_session_or_404, _require_member

logger = logging.getLogger("popal.group_voting")

POSITIVE_VOTE_TYPES = {"LIKE", "LOVE"}


def _member_count(db: Session, session_id: int) -> int:
    return int(
        db.query(func.count(GroupSessionMember.user_id))
        .filter(GroupSessionMember.session_id == session_id)
        .scalar()
        or 0
    )


def _get_recommendation_or_404(db: Session, recommendation_id: int) -> GroupRecommendation:
    rec = (
        db.query(GroupRecommendation)
        .options(joinedload(GroupRecommendation.dish).joinedload(Dish.restaurant))
        .filter(GroupRecommendation.id == recommendation_id)
        .first()
    )
    if not rec:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group recommendation not found",
        )
    return rec


def _get_or_create_decision(db: Session, session_id: int) -> GroupDecision:
    decision = db.query(GroupDecision).filter(GroupDecision.session_id == session_id).first()
    if decision is None:
        decision = GroupDecision(session_id=session_id, status=PENDING)
        db.add(decision)
        db.flush()
    return decision


def persist_recommendation_snapshots(
    db: Session,
    session_id: int,
    recommendations: list[GroupDishRecommendation],
) -> dict[int, GroupRecommendation]:
    """Persist top recommendations and reset open decision state."""
    persisted: dict[int, GroupRecommendation] = {}
    for item in recommendations:
        recommendation_score = float(item.score)
        row = GroupRecommendation(
            session_id=session_id,
            dish_id=item.dish_id,
            recommendation_score=recommendation_score,
            consensus_score=0,
            final_score=recommendation_score,
        )
        db.add(row)
        persisted[item.dish_id] = row

    decision = _get_or_create_decision(db, session_id)
    if decision.status != ORDERED:
        decision.status = PENDING
        decision.recommendation_id = None

    db.flush()
    db.commit()
    for row in persisted.values():
        db.refresh(row)
    return persisted


def enrich_recommendations_response(
    db: Session,
    response: GroupRecommendationsResponse,
    persisted: dict[int, GroupRecommendation],
) -> GroupRecommendationsResponse:
    enriched: list[GroupDishRecommendation] = []
    for item in response.recommendations:
        row = persisted.get(item.dish_id)
        enriched.append(
            item.model_copy(
                update={
                    "recommendation_id": row.id if row else None,
                    "consensus_score": float(row.consensus_score) if row else 0.0,
                    "final_score": float(row.final_score) if row else item.score,
                }
            )
        )
    enriched.sort(key=lambda row: (-(row.final_score or row.score), row.dish_id))
    return response.model_copy(update={"recommendations": enriched})


def get_group_recommendations_with_snapshots(
    db: Session,
    user_id: int,
    session_id: int,
) -> GroupRecommendationsResponse:
    """Generate recommendations via existing engine, then persist snapshots."""
    response = get_group_recommendations(db, user_id, session_id)
    persisted = persist_recommendation_snapshots(db, session_id, response.recommendations)
    return enrich_recommendations_response(db, response, persisted)


def _load_votes_for_recommendations(
    db: Session,
    recommendation_ids: list[int],
) -> dict[int, list[GroupVote]]:
    if not recommendation_ids:
        return {}
    rows = db.query(GroupVote).filter(GroupVote.recommendation_id.in_(recommendation_ids)).all()
    grouped: dict[int, list[GroupVote]] = {rid: [] for rid in recommendation_ids}
    for vote in rows:
        grouped.setdefault(vote.recommendation_id, []).append(vote)
    return grouped


def _update_recommendation_scores(
    db: Session,
    recommendation: GroupRecommendation,
    *,
    member_count: int,
    votes: list[GroupVote],
) -> tuple[float, float]:
    vote_types = [vote.vote_type for vote in votes]
    consensus = compute_consensus_score(vote_types, member_count)
    recommendation_score = float(recommendation.recommendation_score)
    final = compute_final_score(recommendation_score, consensus)
    recommendation.consensus_score = consensus
    recommendation.final_score = final
    return consensus, final


def _evaluate_session_decision(
    db: Session,
    session_id: int,
    *,
    member_count: int,
    recommendations: list[GroupRecommendation],
    votes_by_rec: dict[int, list[GroupVote]],
) -> GroupDecision:
    decision = _get_or_create_decision(db, session_id)
    if decision.status == ORDERED:
        return decision

    any_votes = any(votes_by_rec.values())
    agreed_candidates: list[GroupRecommendation] = []

    for recommendation in recommendations:
        votes = votes_by_rec.get(recommendation.id, [])
        vote_types = [vote.vote_type for vote in votes]
        if should_mark_agreed(count_positive_voters(vote_types), member_count):
            agreed_candidates.append(recommendation)

    if agreed_candidates:
        winner = max(agreed_candidates, key=lambda rec: float(rec.final_score))
        decision.status = AGREED
        decision.recommendation_id = winner.id
        logger.info(
            "GROUP_DECISION_AGREED session_id=%s recommendation_id=%s final_score=%s",
            session_id,
            winner.id,
            winner.final_score,
        )
    elif any_votes:
        decision.status = CONSIDERING
        top = max(recommendations, key=lambda rec: float(rec.final_score), default=None)
        decision.recommendation_id = top.id if top else None
    else:
        decision.status = PENDING
        decision.recommendation_id = None

    return decision


def cast_group_vote(
    db: Session,
    user_id: int,
    recommendation_id: int,
    vote_type: str,
) -> GroupVoteResponse:
    recommendation = _get_recommendation_or_404(db, recommendation_id)
    session = _get_session_or_404(db, recommendation.session_id)
    _require_member(session, user_id)

    existing = (
        db.query(GroupVote)
        .filter(
            GroupVote.recommendation_id == recommendation_id,
            GroupVote.user_id == user_id,
        )
        .first()
    )
    if existing:
        existing.vote_type = vote_type
        vote = existing
    else:
        vote = GroupVote(
            recommendation_id=recommendation_id,
            user_id=user_id,
            vote_type=vote_type,
        )
        db.add(vote)

    db.flush()

    logger.info(
        "GROUP_VOTE_CAST recommendation_id=%s user_id=%s vote_type=%s",
        recommendation_id,
        user_id,
        vote_type,
    )

    member_count = _member_count(db, session.id)
    session_recs = (
        db.query(GroupRecommendation)
        .filter(GroupRecommendation.session_id == session.id)
        .all()
    )
    rec_ids = [rec.id for rec in session_recs]
    votes_by_rec = _load_votes_for_recommendations(db, rec_ids)

    consensus, final = _update_recommendation_scores(
        db,
        recommendation,
        member_count=member_count,
        votes=votes_by_rec.get(recommendation_id, []),
    )
    logger.info(
        "GROUP_CONSENSUS_UPDATED recommendation_id=%s consensus_score=%s final_score=%s",
        recommendation_id,
        consensus,
        final,
    )

    _evaluate_session_decision(
        db,
        session.id,
        member_count=member_count,
        recommendations=session_recs,
        votes_by_rec=votes_by_rec,
    )

    db.commit()
    db.refresh(vote)
    return GroupVoteResponse.model_validate(vote)


def get_vote_summary(db: Session, user_id: int, recommendation_id: int) -> GroupVoteSummaryResponse:
    recommendation = _get_recommendation_or_404(db, recommendation_id)
    session = _get_session_or_404(db, recommendation.session_id)
    _require_member(session, user_id)

    votes = (
        db.query(GroupVote)
        .filter(GroupVote.recommendation_id == recommendation_id)
        .all()
    )
    vote_types = [vote.vote_type for vote in votes]
    summary = summarize_votes(vote_types)
    member_count = _member_count(db, session.id)
    consensus = compute_consensus_score(vote_types, member_count)
    final = compute_final_score(float(recommendation.recommendation_score), consensus)

    return GroupVoteSummaryResponse(
        **summary,
        consensus_score=consensus,
        final_score=final,
    )


def _decision_to_response(decision: GroupDecision) -> GroupDecisionResponse:
    rec = decision.recommendation
    dish = rec.dish if rec else None
    restaurant = dish.restaurant if dish and dish.restaurant else None
    return GroupDecisionResponse(
        id=decision.id,
        session_id=decision.session_id,
        recommendation_id=decision.recommendation_id,
        status=decision.status,
        created_at=decision.created_at,
        updated_at=decision.updated_at,
        consensus_score=float(rec.consensus_score) if rec else None,
        final_score=float(rec.final_score) if rec else None,
        dish_id=dish.id if dish else None,
        dish_name=dish.name if dish else None,
        restaurant_name=restaurant.name if restaurant else None,
        price=dish.price if dish else None,
    )


def get_group_decision(db: Session, user_id: int, session_id: int) -> GroupDecisionResponse:
    session = _get_session_or_404(db, session_id)
    _require_member(session, user_id)

    decision = (
        db.query(GroupDecision)
        .options(
            joinedload(GroupDecision.recommendation)
            .joinedload(GroupRecommendation.dish)
            .joinedload(Dish.restaurant)
        )
        .filter(GroupDecision.session_id == session_id)
        .first()
    )
    if decision is None:
        decision = _get_or_create_decision(db, session_id)
        db.commit()
        db.refresh(decision)

    return _decision_to_response(decision)


def mark_group_decision_ordered(db: Session, user_id: int, session_id: int) -> GroupDecisionResponse:
    session = _get_session_or_404(db, session_id)
    _require_member(session, user_id)

    decision = _get_or_create_decision(db, session_id)
    if decision.status != AGREED or not decision.recommendation_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Group must reach agreed status before marking ordered",
        )

    decision.status = ORDERED
    db.commit()
    db.refresh(decision)

    decision = (
        db.query(GroupDecision)
        .options(
            joinedload(GroupDecision.recommendation)
            .joinedload(GroupRecommendation.dish)
            .joinedload(Dish.restaurant)
        )
        .filter(GroupDecision.id == decision.id)
        .first()
    )
    logger.info(
        "GROUP_DECISION_ORDERED session_id=%s recommendation_id=%s",
        session_id,
        decision.recommendation_id if decision else None,
    )
    return _decision_to_response(decision)
