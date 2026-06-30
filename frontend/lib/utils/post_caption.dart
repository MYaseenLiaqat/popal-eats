/// Strip internal HTML seed markers from post captions before display.
String displayPostCaption(String? caption) {
  if (caption == null || caption.isEmpty) return '';
  return caption
      .replaceAll(RegExp(r'<!--\s*fyp_seed_v\d+\s*-->', caseSensitive: false), '')
      .replaceAll(RegExp(r'<!--\s*fyp\.community\s*-->', caseSensitive: false), '')
      .trim();
}

bool hasVisibleCaption(String? caption) => displayPostCaption(caption).isNotEmpty;
