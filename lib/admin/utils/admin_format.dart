abstract final class AdminFormat {
  static String currency(double value) => '${value.toStringAsFixed(0)} ج.م';

  static String dateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} — $h:$m';
  }

  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return dateTime(dt);
  }

  static String durationSeconds(int seconds) {
    if (seconds < 60) return '$seconds ث';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m < 60) return s == 0 ? '$m د' : '$m د $s ث';
    final h = m ~/ 60;
    final rm = m % 60;
    return rm == 0 ? '$h س' : '$h س $rm د';
  }
}
