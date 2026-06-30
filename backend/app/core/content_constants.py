"""Constants for social content (posts, stories, interactions)."""

FOOD_POST = "food_post"
RECIPE = "recipe"
CHEF_POST = "chef_post"
RESTAURANT_POST = "restaurant_post"

POST_TYPES = frozenset({FOOD_POST, RECIPE, CHEF_POST, RESTAURANT_POST})

PROMOTION = "promotion"
NEW_DISH = "new_dish"
ANNOUNCEMENT = "announcement"

RESTAURANT_CONTENT_SUBTYPES = frozenset({PROMOTION, NEW_DISH, ANNOUNCEMENT})

DISCOVER_POST_TYPES = frozenset({RECIPE, CHEF_POST, RESTAURANT_POST})

STORY_TTL_HOURS = 24

CONTENT_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
CONTENT_VIDEO_EXTENSIONS = {".mp4", ".mov", ".webm", ".m4v"}
