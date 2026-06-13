"""Tests for catalog tag normalization and enrichment."""

from app.services.catalog.tag_normalization import normalize_tag, normalize_tags
from app.services.catalog_enrichment_service import CatalogEnrichmentService


class _Restaurant:
    def __init__(self, *, name: str, description: str | None = None, tags=None):
        self.name = name
        self.description = description
        self.tags = tags


class _Category:
    def __init__(self, name: str):
        self.name = name


class _Dish:
    def __init__(self, *, name: str, description: str = "", category_name: str | None = None, tags=None):
        self.name = name
        self.description = description
        self.category = _Category(category_name) if category_name else None
        self.tags = tags


def test_normalize_aliases():
    assert normalize_tag("Burgers") == "burger"
    assert normalize_tag("Fast Food") == "fast_food"
    assert normalize_tag("BBQ") == "bbq"
    assert normalize_tag("Barbecue") == "bbq"
    assert normalize_tag("Desserts") == "desserts"
    assert normalize_tags(["Burger", "burgers", "Pizza", "pizza"]) == ["burger", "pizza"]


def test_derive_restaurant_tags_from_description():
    restaurant = _Restaurant(
        name="Joe's Pizza Hub",
        description="Imported from Foodpanda.\nCuisines: Fast Food, Pizza, Italian",
    )
    tags = CatalogEnrichmentService.derive_restaurant_tags(restaurant)
    assert "pizza" in tags
    assert "fast_food" in tags
    assert "italian" in tags


def test_derive_dish_tags_from_category_and_name():
    dish = _Dish(name="Chicken Biryani Bowl", category_name="Biryani & Pulao")
    tags = CatalogEnrichmentService.derive_dish_tags(
        dish,
        restaurant_tags=["pakistani", "biryani"],
    )
    assert "biryani" in tags
    assert "pakistani" in tags
