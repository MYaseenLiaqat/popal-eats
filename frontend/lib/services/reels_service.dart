import '../data/reels_placeholder_data.dart';
import '../models/reel.dart';

/// Reels API boundary — returns placeholder catalog until backend endpoints exist.
class ReelsService {
  Future<List<Reel>> listReels() async {
    // Simulate network latency for realistic provider flow.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return List<Reel>.from(placeholderReels);
  }
}
