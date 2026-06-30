import '../data/cuisine_catalog.dart';
import '../models/dish.dart';
import '../models/recommendation.dart';
import '../models/restaurant.dart';



/// Groups dish recommendations by restaurant and ranks restaurants by top dish score.

class OrderRecommendationUtils {

  const OrderRecommendationUtils._();



  static const _cuisineAliases = <String, List<String>>{

    'pakistani': ['pakistani', 'pakistan', 'desi', 'biryani', 'karahi'],

    'afghan': ['afghan', 'afghanistan', 'mantu', 'bolani'],

    'turkish': ['turkish', 'turkey', 'doner', 'kebab', 'pide'],

    'chinese': ['chinese', 'china', 'noodle', 'dumpling', 'wok'],

    'korean': ['korean', 'korea', 'kimchi', 'bibimbap', 'bulgogi'],

    'italian': ['italian', 'italy', 'pizza', 'pasta', 'risotto'],

    'arabic': ['arabic', 'arab', 'shawarma', 'falafel', 'mandi', 'lebanese'],

    'persian': ['persian', 'iran', 'iranian', 'tahdig', 'ghormeh'],

    'fast_food': ['fast food', 'fast_food', 'burger', 'fries', 'fried chicken'],

    'desserts': ['dessert', 'desserts', 'cake', 'pastry', 'ice cream', 'sweet'],

    'bbq': ['bbq', 'barbecue', 'grill', 'kebab', 'tikka', 'smoke'],

    'beverages': ['beverage', 'beverages', 'drink', 'juice', 'coffee', 'tea', 'shake'],

  };



  static List<String> _aliasesForKey(String? cuisineKey) {

    if (cuisineKey == null || cuisineKey.isEmpty) return const [];

    final key = cuisineKey.trim().toLowerCase();

    final fromCatalog = CuisineCatalog.byKey(key)?.name.toLowerCase();

    final aliases = <String>{key, if (fromCatalog != null) fromCatalog};

    aliases.addAll(_cuisineAliases[key] ?? const []);

    return aliases.toList();

  }



  static bool _namesMatch(String restaurantName, String recName) {
    final a = restaurantName.trim().toLowerCase();
    final b = recName.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  static Map<String, double> restaurantScores(List<Recommendation> recs) {

    final scores = <String, double>{};

    for (final rec in recs) {

      final name = rec.restaurantName.trim().toLowerCase();

      final current = scores[name];

      if (current == null || rec.score > current) {

        scores[name] = rec.score;

      }

    }

    return scores;

  }



  static List<Restaurant> sortByRecommendationScore(

    List<Restaurant> restaurants,

    List<Recommendation> recs,

  ) {

    final scores = restaurantScores(recs);

    final sorted = List<Restaurant>.from(restaurants);

    sorted.sort((a, b) {

      final sa = scores[a.name.trim().toLowerCase()] ?? 0;

      final sb = scores[b.name.trim().toLowerCase()] ?? 0;

      if (sa != sb) return sb.compareTo(sa);

      return b.averageRating.compareTo(a.averageRating);

    });

    return sorted;

  }



  static List<Restaurant> restaurantsForRecommendations(

    List<Restaurant> all,

    List<Recommendation> recs, {

    int limit = 8,

  }) {

    final matched = <Restaurant>[];

    final seen = <int>{};

    final sortedRecs = List<Recommendation>.from(recs)

      ..sort((a, b) => b.score.compareTo(a.score));

    for (final rec in sortedRecs) {

      if (matched.length >= limit) break;

      for (final restaurant in all) {

        if (seen.contains(restaurant.id)) continue;

        if (_namesMatch(restaurant.name, rec.restaurantName)) {

          matched.add(restaurant);

          seen.add(restaurant.id);

          break;

        }

      }

    }

    return matched;

  }



  static List<Recommendation> healthyPicks(List<Recommendation> recs, {int limit = 8}) {

    final sorted = List<Recommendation>.from(recs);

    sorted.sort((a, b) {

      final na = a.scoreBreakdown?.nutritionScore ?? 0;

      final nb = b.scoreBreakdown?.nutritionScore ?? 0;

      if (na != nb) return nb.compareTo(na);

      return b.score.compareTo(a.score);

    });

    return sorted.take(limit).toList();

  }



  static List<Recommendation> budgetFriendly(List<Recommendation> recs, {int limit = 8}) {

    final sorted = recs

        .where((r) => (r.scoreBreakdown?.budgetScore ?? 0) > 0)

        .toList();

    sorted.sort((a, b) {

      final ba = a.scoreBreakdown?.budgetScore ?? 0;

      final bb = b.scoreBreakdown?.budgetScore ?? 0;

      if (ba != bb) return bb.compareTo(ba);

      return a.price.compareTo(b.price);

    });

    return sorted.take(limit).toList();

  }



  static List<Recommendation> recommendedForYou(List<Recommendation> recs, {int limit = 8}) {
    final sorted = List<Recommendation>.from(recs)
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(limit).toList();
  }

  static List<Recommendation> nearbyPicks(List<Recommendation> recs, {int limit = 8}) {
    final sorted = recs
        .where((r) => (r.scoreBreakdown?.popularityScore ?? 0) > 0)
        .toList();
    sorted.sort((a, b) {
      final pa = a.scoreBreakdown?.popularityScore ?? 0;
      final pb = b.scoreBreakdown?.popularityScore ?? 0;
      if (pa != pb) return pb.compareTo(pa);
      return b.score.compareTo(a.score);
    });
    if (sorted.isNotEmpty) return sorted.take(limit).toList();
    return recommendedForYou(recs, limit: limit);
  }

  static List<Recommendation> basedOnOrders(List<Recommendation> recs, {int limit = 8}) {

    final sorted = recs

        .where((r) => (r.scoreBreakdown?.collaborativeScore ?? 0) > 0)

        .toList();

    sorted.sort((a, b) {

      final ca = a.scoreBreakdown?.collaborativeScore ?? 0;

      final cb = b.scoreBreakdown?.collaborativeScore ?? 0;

      if (ca != cb) return cb.compareTo(ca);

      return b.score.compareTo(a.score);

    });

    return sorted.take(limit).toList();

  }



  static bool _restaurantMatchesCuisine(Restaurant restaurant, List<String> aliases) {

    final tagBlob = restaurant.tags.join(' ').toLowerCase();

    final name = restaurant.name.toLowerCase();

    final description = (restaurant.description ?? '').toLowerCase();

    return aliases.any(

      (alias) =>

          tagBlob.contains(alias) ||

          name.contains(alias) ||

          description.contains(alias),

    );

  }



  static List<Restaurant> filterByCuisine(

    List<Restaurant> restaurants,

    String? cuisineKey,

  ) {

    if (cuisineKey == null || cuisineKey.isEmpty) return restaurants;

    final aliases = _aliasesForKey(cuisineKey);

    if (aliases.isEmpty) return restaurants;

    return restaurants

        .where((r) => _restaurantMatchesCuisine(r, aliases))

        .toList();

  }



  static bool dishMatchesCuisine(Dish dish, String cuisineKey) {
    final aliases = _aliasesForKey(cuisineKey);
    final name = dish.name.toLowerCase();
    final cuisine = (dish.cuisine ?? '').toLowerCase();
    return aliases.any((a) => name.contains(a) || cuisine.contains(a));
  }

  static List<Restaurant> filterBySearch(

    List<Restaurant> restaurants,

    String query,

  ) {

    final needle = query.trim().toLowerCase();

    if (needle.isEmpty) return restaurants;

    return restaurants.where((r) {

      final name = r.name.toLowerCase();

      final tags = r.tags.join(' ').toLowerCase();

      final description = (r.description ?? '').toLowerCase();

      return name.contains(needle) ||

          tags.contains(needle) ||

          description.contains(needle);

    }).toList();

  }



  static List<Recommendation> filterRecommendations(

    List<Recommendation> recs, {

    String? query,

    String? cuisineKey,

  }) {

    var filtered = recs;

    if (cuisineKey != null && cuisineKey.isNotEmpty) {

      final aliases = _aliasesForKey(cuisineKey);

      filtered = filtered

          .where(

            (r) => aliases.any(

              (alias) =>

                  r.restaurantName.toLowerCase().contains(alias) ||

                  r.dishName.toLowerCase().contains(alias) ||

                  r.explanation.toLowerCase().contains(alias),

            ),

          )

          .toList();

    }

    if (query != null && query.trim().isNotEmpty) {

      final needle = query.trim().toLowerCase();

      filtered = filtered

          .where(

            (r) =>

                r.dishName.toLowerCase().contains(needle) ||

                r.restaurantName.toLowerCase().contains(needle) ||

                r.explanation.toLowerCase().contains(needle),

          )

          .toList();

    }

    return filtered;

  }

}

