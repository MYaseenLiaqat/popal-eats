import 'package:flutter/foundation.dart';

import '../data/reels_placeholder_data.dart';
import '../models/reel.dart';
import '../services/reels_service.dart';

/// State for recipe & chef reels (placeholder content until video API ships).
class ReelsProvider extends ChangeNotifier {
  ReelsProvider({ReelsService? service}) : _service = service ?? ReelsService();

  final ReelsService _service;

  List<Reel> reels = [];
  bool loading = false;
  String? error;
  int currentIndex = 0;

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
      error = e.toString();
      reels = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Offline-friendly fallback used by the service layer today.
  List<Reel> get placeholderCatalog => placeholderReels;
}
