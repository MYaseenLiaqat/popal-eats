import 'package:flutter/material.dart';

/// Local asset paths and crop alignment for allergy onboarding imagery.
abstract final class AllergyAssets {
  static const basePath = 'assets/images/allergies';

  // Filenames as stored on disk (including original spellings).
  static const bread = '$basePath/bread.jpg';
  static const celery = '$basePath/cellery.jpg';
  static const eggs = '$basePath/eggs.jpg';
  static const fish = '$basePath/fish.jpg';
  static const lupin = '$basePath/lupin.jpg';
  static const mustard = '$basePath/mustard.jpg';
  static const peanuts = '$basePath/peanuts.jpg';
  static const seafood = '$basePath/seafood.jpg';
  static const sesame = '$basePath/seaseme.jpg';
  static const soy = '$basePath/soy.jpg';
  static const wheat = '$basePath/wheat.jpg';
  static const sulphites = '$basePath/wine (1).jpg';
  static const molluscs = '$basePath/muscels.jpg';

  static const _byKey = <String, String>{
    'gluten': bread,
    'celery': celery,
    'eggs': eggs,
    'fish': fish,
    'lupin': lupin,
    'dairy': '$basePath/milk.jpg',
    'mustard': mustard,
    'peanuts': peanuts,
    'shellfish': seafood,
    'sesame': sesame,
    'soy': soy,
    'wheat': wheat,
    'sulphites': sulphites,
    'molluscs': molluscs,
  };

  static const _alignmentByKey = <String, Alignment>{
    'celery': Alignment.topCenter,
  };

  static String pathFor(String key) {
    return _byKey[key.trim().toLowerCase()] ?? bread;
  }

  static Alignment alignmentFor(String key) {
    return _alignmentByKey[key.trim().toLowerCase()] ?? Alignment.center;
  }
}
