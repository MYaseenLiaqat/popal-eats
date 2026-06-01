"""Personalized dish recommendations (Engine V1)."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.recommendation import DishRecommendationItem, RecommendationsResponse
from app.services.recommendation_service import get_recommendations

router = APIRouter(tags=["recommendations"])


@router.get(
    "/recommendations",
    response_model=RecommendationsResponse,
    summary="Get personalized dish recommendations",
    description=(
        "Returns up to **10 dishes** ranked for the authenticated user using **Recommendation Engine V1**.\n\n"
        "**Inputs:** `GET /users/preferences` profile (cuisines, budget, nutrition goal).\n\n"
        "**Scoring (max 100):**\n"
        "- Cuisine match — **40** (favorite cuisines vs dish/category/restaurant text)\n"
        "- Nutrition match — **25** (macros vs `nutrition_goal`)\n"
        "- Budget match — **20** (price within `budget_min`–`budget_max`)\n"
        "- Restaurant rating — **15** (`average_rating` / 5 × 15)\n\n"
        "Requires JWT Bearer token from `POST /login`."
    ),
)
def list_recommendations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    scored = get_recommendations(db, current_user.id)
    items = [DishRecommendationItem.model_validate(row) for row in scored]
    return RecommendationsResponse(items=items, count=len(items))
