"""Admin API routes — RBAC protected."""

from fastapi import APIRouter

from app.routes.admin.analytics import router as analytics_router
from app.routes.admin.catalog import router as catalog_admin_router
from app.routes.admin.menu import router as menu_admin_router
from app.routes.admin.recommendations import router as recommendations_admin_router
from app.routes.admin.reviews import router as reviews_admin_router
from app.routes.admin.business_accounts import router as business_accounts_admin_router
from app.routes.admin.restaurants import router as restaurants_admin_router
from app.routes.admin.users import router as users_admin_router

router = APIRouter(prefix="/admin", tags=["admin"])

router.include_router(analytics_router)
router.include_router(catalog_admin_router)
router.include_router(recommendations_admin_router)
router.include_router(reviews_admin_router)
router.include_router(menu_admin_router)
router.include_router(restaurants_admin_router)
router.include_router(business_accounts_admin_router)
router.include_router(users_admin_router)
