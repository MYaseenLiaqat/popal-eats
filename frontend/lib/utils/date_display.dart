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

  static String _month(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
