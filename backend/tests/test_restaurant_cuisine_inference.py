"""Tests for restaurant cuisine inference from menu composition."""

from app.services.catalog_enrichment_service import CatalogEnrichmentService
from app.services.restaurant_cuisine_inference_service import RestaurantCuisineInferenceService


class _Category:
    def __init__(self, name: str):
        self.name = name


class _Dish:
    def __init__(
        self,
        *,
        name: str,
        description: str = "",
        category_name: str | None = None,
        tags=None,
    ):
        self.name = name
        self.description = description
        self.category = _Category(category_name) if category_name else None
        self.tags = tags


class _Restaurant:
    def __init__(self, *, name: str, description: str | None = None, tags=None):
        self.name = name
        self.description = description
        self.tags = tags


def test_infer_burger_fast_food_dominant_menu():
    dishes = [
        _Dish(name="Beef Burger", category_name="Burgers", tags=["burger", "fast_food"]),
        _Dish(name="Chicken Burger", category_name="Burgers", tags=["burger", "fast_food"]),
        _Dish(name="Zinger Burger", category_name="Burgers", tags=["burger", "fast_food"]),
        _Dish(name="Hot Wings", category_name="Wings", tags=["wings", "fast_food"]),
        _Dish(name="Pepsi", category_name="Drinks", tags=["beverages"]),
    ]
    result = RestaurantCuisineInferenceService().infer_from_dishes(dishes)
    assert "burger" in result.inferred_tags
    assert "fast_food" in result.inferred_tags
    assert result.confidence >= 0.5
    assert result.confidence <= 1.0


def test_infer_empty_menu_returns_zero_confidence():
    result = RestaurantCuisineInferenceService().infer_from_dishes([])
    assert result.inferred_tags == []
    assert result.confidence == 0.0


def test_resolve_restaurant_tags_falls_back_to_inference():
    restaurant = _Restaurant(name="Generic Place", description="Imported from Foodpanda.")
    dishes = [
        _Dish(name="Margherita Pizza", category_name="Pizza", tags=["pizza", "italian"]),
        _Dish(name="Pepperoni Pizza", category_name="Pizza", tags=["pizza", "italian"]),
        _Dish(name="Garlic Bread", category_name="Sides", tags=["italian"]),
    ]
    service = CatalogEnrichmentService()
    tags, inference = service.resolve_restaurant_tags(restaurant, dishes=dishes)
    assert tags == ["italian", "pizza"] or tags == ["pizza", "italian"]
    assert inference is not None
    assert inference.confidence > 0


def test_primary_tags_skip_inference():
    restaurant = _Restaurant(
        name="Joe's Pizza",
        description="Imported from Foodpanda.\nCuisines: Pizza, Italian",
    )
    dishes = [_Dish(name="Burger", tags=["burger"])]
    service = CatalogEnrichmentService()
    tags, inference = service.resolve_restaurant_tags(restaurant, dishes=dishes)
    assert "pizza" in tags
    assert inference is None
