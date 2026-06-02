"""Personalized dish recommendations (Engine V1.1)."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.recommendation import (
    DishRecommendationItem,
    RecommendationsResponse,
    ScoreBreakdown,
)
from app.services.recommendation_service import get_recommendations

router = APIRouter(tags=["recommendations"])


@router.get(
    "/recommendations",
    response_model=RecommendationsResponse,
    summary="Get personalized dish recommendations (V1.1)",
    description=(
        "Returns up to **10 dishes** ranked for the authenticated user using **Recommendation Engine V1.1**.\n\n"
        "**Inputs:** `GET /users/preferences` (cuisines, budget, nutrition goal).\n\n"
        "**Scoring (max 100):**\n"
        "- Cuisine — **40** (dish tags → restaurant tags → category name → text)\n"
        "- Nutrition — **25** (macros vs `nutrition_goal`)\n"
        "- Budget — **20** (within `budget_min`–`budget_max`; no credit below minimum)\n"
        "- Restaurant rating — **15** (`average_rating` / 5 × 15)\n\n"
        "**V1.1 additions:** `score_breakdown` per item, detailed `explanation`, fixed budget messaging.\n\n"
        "Requires JWT Bearer token from `POST /login`."
    ),
)
def list_recommendations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    scored = get_recommendations(db, current_user.id)
    items = [
        DishRecommendationItem(
            dish_id=row.dish_id,
            dish_name=row.dish_name,
            restaurant_name=row.restaurant_name,
            price=row.price,
            calories=row.calories,
            recommendation_score=row.recommendation_score,
            score_breakdown=row.score_breakdown,
            explanation=row.explanation,
        )
        for row in scored
    ]
    return RecommendationsResponse(items=items, count=len(items), engine_version="1.1")
