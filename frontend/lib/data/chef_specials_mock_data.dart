class MockFeaturedChef {
  const MockFeaturedChef({
    required this.name,
    required this.title,
    required this.specialty,
    required this.recipeCount,
  });

  final String name;
  final String title;
  final String specialty;
  final int recipeCount;
}

class MockChefRecipe {
  const MockChefRecipe({
    required this.name,
    required this.calories,
    required this.cuisine,
    required this.chefName,
  });

  final String name;
  final int calories;
  final String cuisine;
  final String chefName;
}

const mockFeaturedChef = MockFeaturedChef(
  name: 'Chef Hassan Mahmood',
  title: 'Chef of the Week',
  specialty: 'Healthy Pakistani Fusion',
  recipeCount: 12,
);

const mockChefRecipes = [
  MockChefRecipe(
    name: 'Chef Special Chicken Bowl',
    calories: 520,
    cuisine: 'Pakistani',
    chefName: 'Chef Hassan',
  ),
  MockChefRecipe(
    name: 'Grilled Herb Salmon Plate',
    calories: 480,
    cuisine: 'Mediterranean',
    chefName: 'Chef Sara',
  ),
  MockChefRecipe(
    name: 'Protein Power Pasta',
    calories: 610,
    cuisine: 'Italian',
    chefName: 'Chef Ali',
  ),
];
