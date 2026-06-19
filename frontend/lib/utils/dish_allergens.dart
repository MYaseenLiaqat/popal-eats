/// Supported dish allergen tags (matches backend DISH_ALLERGENS).
class DishAllergens {
  DishAllergens._();

  static const options = [
    ('peanut', 'Peanut'),
    ('dairy', 'Dairy'),
    ('gluten', 'Gluten'),
    ('soy', 'Soy'),
    ('egg', 'Egg'),
    ('shellfish', 'Shellfish'),
    ('tree_nut', 'Tree nut'),
  ];
}
