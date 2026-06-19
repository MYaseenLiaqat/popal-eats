import '../data/reels_placeholder_data.dart';
import '../models/reel.dart';
import 'content_service.dart';

/// Reels API — discover content with placeholder fallback.
class ReelsService {
  ReelsService({ContentService? content}) : _content = content ?? ContentService();

  final ContentService _content;

  Future<List<Reel>> listReels() async {
    try {
      final raw = await _content.fetchDiscoverReels();
      if (raw.isNotEmpty) {
        return raw.map((e) => Reel.fromJson(e)).toList();
      }
    } catch (_) {
      // Fall back to placeholders when API unavailable or empty.
    }
    return List<Reel>.from(placeholderReels);
  }
}
