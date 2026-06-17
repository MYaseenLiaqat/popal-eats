import 'package:flutter_test/flutter_test.dart';
import 'package:popal_eats/models/reel.dart';

void main() {
  test('Reel parses API payload', () {
    final reel = Reel.fromJson({
      'id': 'abc',
      'kind': 'chef',
      'title': 'Test reel',
      'creator_name': 'Chef Test',
      'caption': 'Caption',
      'thumbnail_url': '/media/thumb.jpg',
      'video_url': 'https://example.com/v.mp4',
      'duration_label': '1:00',
    });

    expect(reel.id, 'abc');
    expect(reel.kind, ReelKind.chef);
    expect(reel.title, 'Test reel');
    expect(reel.creatorName, 'Chef Test');
    expect(reel.hasVideo, isTrue);
    expect(reel.kindLabel, 'Chef reel');
  });
}
