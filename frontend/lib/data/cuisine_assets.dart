/// Local asset paths for cuisine onboarding imagery.
abstract final class CuisineAssets {
  static const basePath = 'assets/images/cuisines';

  static const pakistani = '$basePath/pakistani.jpg';
  static const afghan = '$basePath/afghan.jpg';
  static const turkish = '$basePath/turkish.jpg';
  static const chinese = '$basePath/chinese.jpg';
  static const korean = '$basePath/korean.jpg';
  static const italian = '$basePath/italian.jpg';
  static const arabic = '$basePath/arab.jpg';
  static const persian = '$basePath/persian.jpg';
  static const fastFood = '$basePath/fast food.jpg';
  static const desserts = '$basePath/desert.jpg';

  static const _byKey = <String, String>{
    'pakistani': pakistani,
    'afghan': afghan,
    'turkish': turkish,
    'chinese': chinese,
    'korean': korean,
    'italian': italian,
    'arabic': arabic,
    'persian': persian,
    'fast_food': fastFood,
    'desserts': desserts,
  };

  static String pathFor(String key) {
    return _byKey[key.trim().toLowerCase()] ?? pakistani;
  }
}
