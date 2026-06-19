/// Display helpers for user identity across the app.
class UserDisplay {
  UserDisplay._();

  static String handle({
    String? username,
    String? email,
    int? userId,
  }) {
    if (username != null && username.trim().isNotEmpty) {
      final normalized = username.trim().toLowerCase();
      return normalized.startsWith('@') ? normalized : '@$normalized';
    }
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim().toLowerCase();
      if (local.isNotEmpty) return '@$local';
    }
    if (userId != null) return '@user$userId';
    return '@guest';
  }

  static String? cityLine(String? city) {
    final trimmed = city?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
