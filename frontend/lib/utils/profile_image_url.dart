import '../config/api_config.dart';

String? resolveProfileImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '${ApiConfig.baseUrl}$trimmed';
  }
  return '${ApiConfig.baseUrl}/$trimmed';
}
