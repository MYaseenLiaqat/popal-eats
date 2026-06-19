/// Hides Foodpanda menu-import category labels from consumer UI.
class MenuCategoryFilter {
  MenuCategoryFilter._();

  static final _blocked = RegExp(
    r'pepperoni|add[\s-]?on|deal|premium beef|combo|extra|side[s]?|'
    r'sauces?|toppings?|beverages? only|\d+\s*pc|\d+\s*pcs',
    caseSensitive: false,
  );

  /// True when the label looks like a raw vendor menu section.
  static bool isFoodpandaMenuCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return true;
    if (_blocked.hasMatch(trimmed)) return true;
    // Pure numeric category names from imports (e.g. "100 Pepperoni")
    if (RegExp(r'^\d+\s').hasMatch(trimmed)) return true;
    return false;
  }

  /// Consumer-facing section title.
  static String displayLabel(String name) {
    if (isFoodpandaMenuCategory(name)) return 'Menu';
    return name.trim();
  }
}
