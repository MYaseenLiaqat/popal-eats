class DateDisplay {
  DateDisplay._();

  static String formatShort(DateTime value) {
    final local = value.toLocal();
    final month = _month(local.month);
    return '$month ${local.day}, ${local.year}';
  }

  static String formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${formatShort(local)} · $hour:$minute $period';
  }

  static String formatRelativeExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.toLocal().difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inHours >= 24) return 'Expires in ${diff.inDays}d';
    if (diff.inHours >= 1) return 'Expires in ${diff.inHours}h';
    if (diff.inMinutes >= 1) return 'Expires in ${diff.inMinutes}m';
    return 'Expires soon';
  }

  static String formatRelativeUpdated(DateTime updatedAt) {
    final now = DateTime.now();
    final diff = now.difference(updatedAt.toLocal());
    if (diff.isNegative || diff.inSeconds < 30) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDateTime(updatedAt);
  }

  static String _month(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
