import '../models/restaurant.dart';

/// UI-only helpers for restaurant metadata not exposed as dedicated API fields.
class RestaurantDisplay {
  RestaurantDisplay._();

  static final _deliveryPattern = RegExp(
    r'(\d{1,2}\s*[–\-]\s*\d{1,2}|\d{1,2})\s*min',
    caseSensitive: false,
  );

  static final _distancePattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*km',
    caseSensitive: false,
  );

  /// Parses delivery ETA embedded in enrichment description or tags.
  static String? deliveryEta(Restaurant restaurant) {
    final desc = restaurant.description ?? '';
    final match = _deliveryPattern.firstMatch(desc);
    if (match != null) {
      final raw = match.group(0)!.replaceAll(' ', '');
      return raw.contains('min') ? raw : '$raw min';
    }

    for (final tag in restaurant.tags) {
      final tagMatch = _deliveryPattern.firstMatch(tag);
      if (tagMatch != null) {
        return tagMatch.group(0)!.trim();
      }
      if (tag.toLowerCase().contains('fast')) return '20–30 min';
    }

    return '25–35 min';
  }

  /// Parses distance when present in description; otherwise a stable estimate.
  static String distanceLabel(Restaurant restaurant) {
    final desc = restaurant.description ?? '';
    final match = _distancePattern.firstMatch(desc);
    if (match != null) return '${match.group(1)} km';

    // Stable pseudo-distance from id for demo consistency (no geolocation API).
    final km = 1.2 + (restaurant.id % 47) / 10.0;
    return '${km.toStringAsFixed(1)} km';
  }
}
