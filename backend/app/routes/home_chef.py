"""Home chef business dashboard routes — reuses kitchen restaurant backend."""

import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session, joinedload

from app.config import MAX_UPLOAD_MB, UPLOAD_DIR
from app.core.content_constants import CONTENT_IMAGE_EXTENSIONS
from app.core.rbac import assert_active_business_account, require_home_chef
from app.database import get_db
from app.models.order import Order
from app.models.user import User
from app.schemas.content import PostListResponse, PostResponse
from app.schemas.home_chef import (
    HomeChefDashboardResponse,
    HomeChefProfileResponse,
    HomeChefProfileUpdate,
)
from app.schemas.order import OrderResponse
from app.services.home_chef_service import (
    build_home_chef_dashboard,
    get_home_chef_profile_or_404,
    get_kitchen_restaurant,
    list_home_chef_posts,
    sync_kitchen_from_profile,
)
from app.core.permissions import assert_restaurant_owner

router = APIRouter(prefix="/home-chef", tags=["home-chef"])


def _public_profile_url(relative_path: str) -> str:
    return f"/uploads/{relative_path.replace(chr(92), '/')}"


def _profile_response(db: Session, user: User) -> HomeChefProfileResponse:
    profile = get_home_chef_profile_or_404(db, user)
    kitchen = get_kitchen_restaurant(db, user)
    return HomeChefProfileResponse(
        id=profile.id,
        user_id=profile.user_id,
        display_name=profile.display_name,
        cuisine_specialty=profile.cuisine_specialty,
        kitchen_address=profile.kitchen_address,
        food_license=profile.food_license,
        profile_image=profile.profile_image,
        biography=profile.biography,
        kitchen_restaurant_id=kitchen.id,
        phone=user.phone,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )


@router.get("/me", response_model=HomeChefProfileResponse, summary="Home chef profile + kitchen id")
def get_me(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_home_chef),
):
    assert_active_business_account(current_user)
    try:
        return _profile_response(db, current_user)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.put("/me/profile", response_model=HomeChefProfileResponse, summary="Update home chef profile")
def update_profile(
    body: HomeChefProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_home_chef),
):
    assert_active_business_account(current_user)
    try:
        profile = get_home_chef_profile_or_404(db, current_user)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    for key, value in body.model_dump(exclude_unset=True).items():
        if key == "phone":
            current_user.phone = value
        else:
            setattr(profile, key, value)

    sync_kitchen_from_profile(db, profile)
    db.add(profile)
    db.add(current_user)
    db.commit()
    db.refresh(profile)
    return _profile_response(db, current_user)


@router.post("/me/profile/image", response_model=HomeChefProfileResponse, summary="Upload profile image")
async def upload_profile_image(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_home_chef),
):
    assert_active_business_account(current_user)
    try:
        profile = get_home_chef_profile_or_404(db, current_user)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in CONTENT_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Allowed types: {', '.join(sorted(CONTENT_IMAGE_EXTENSIONS))}",
        )

    content = await file.read()
    if len(content) > MAX_UPLOAD_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"Max {MAX_UPLOAD_MB}MB")

    image_dir = UPLOAD_DIR / "home_chefs"
    image_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{profile.id}_{uuid.uuid4().hex}{suffix}"
    dest = image_dir / filename
    dest.write_bytes(content)

    public_url = _public_profile_url(f"home_chefs/{filename}")
    profile.profile_image = public_url
    current_user.profile_image = public_url
    sync_kitchen_from_profile(db, profile)
    db.add(profile)
    db.add(current_user)
    db.commit()
    return _profile_response(db, current_user)


@router.get("/dashboard", response_model=HomeChefDashboardResponse, summary="Home chef dashboard metrics")
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_home_chef),
):
    assert_active_business_account(current_user)
    try:
        data = build_home_chef_dashboard(db, current_user)
        return HomeChefDashboardResponse(**data)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/analytics", response_model=HomeChefDashboardResponse, summary="Home chef analytics")
def get_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_home_chef),
):
    assert_active_business_account(current_user)
    try:
        data = build_home_chef_dashboard(db, current_user)
        return HomeChefDashboardResponse(**data)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/orders", response_model=list[OrderResponse], summary="Home chef kitchen orders")
def list_orders(
    skip: int = 0,
    limit: int = 50,
    status: str | None = Query(None, description="Filter by order status"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_home_chef),
):
    assert_active_business_account(current_user)
    try:
        kitchen = get_kitchen_restaurant(db, current_user)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    assert_restaurant_owner(kitchen, current_user)

    query = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.restaurant_id == kitchen.id)
    )
    if status:
        query = query.filter(Order.status == status.strip().lower())
    orders = query.order_by(Order.created_at.desc()).offset(skip).limit(limit).all()
    return [OrderResponse.model_validate(o) for o in orders]


@router.get("/posts", response_model=PostListResponse, summary="Home chef content posts")
def list_posts(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_home_chef),
):
    assert_active_business_account(current_user)
    items, total = list_home_chef_posts(db, current_user, page=page, limit=limit)
    return PostListResponse(
        items=[PostResponse.model_validate(p) for p in items],
        page=page,
        limit=limit,
        total_count=total,
    )
