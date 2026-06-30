import 'package:flutter/foundation.dart';

import '../models/reel.dart';
import '../services/reels_service.dart';
import '../utils/recommendation_copy.dart';

/// State for recipe & chef reels from the discover API.
class ReelsProvider extends ChangeNotifier {
  ReelsProvider({ReelsService? service}) : _service = service ?? ReelsService();

  final ReelsService _service;

  List<Reel> reels = [];
  bool loading = false;
  String? error;
  int currentIndex = 0;

  bool get hasReels => reels.isNotEmpty;

  Future<void> reset() async {
    reels = [];
    loading = false;
    error = null;
    currentIndex = 0;
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    if (index == currentIndex) return;
    if (index < 0 || (reels.isNotEmpty && index >= reels.length)) return;
    currentIndex = index;
    notifyListeners();
  }

  Future<void> fetch({bool force = false}) async {
    if (loading) return;
    if (!force && reels.isNotEmpty && error == null) return;

    loading = true;
    error = null;
    notifyListeners();

    try {
      reels = await _service.listReels();
      if (currentIndex >= reels.length) {
        currentIndex = 0;
      }
    } catch (e) {
      error = RecommendationCopy.friendlyError(e);
      reels = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
