import '../models/reel.dart';
import 'content_service.dart';

/// Reels API — discover content only (no placeholder fallback).
class ReelsService {
  ReelsService({ContentService? content}) : _content = content ?? ContentService();

  final ContentService _content;

  Future<List<Reel>> listReels() async {
    final raw = await _content.fetchDiscoverReels();
    return raw.map((e) => Reel.fromJson(e)).toList();
  }
}
