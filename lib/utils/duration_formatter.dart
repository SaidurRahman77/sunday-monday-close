class DurationFormatter {
  const DurationFormatter._();

  static String formatHours(int hours) {
    if (hours <= 0) return 'Duration not set';

    final days = hours ~/ 24;
    final remainingHours = hours % 24;

    if (days == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    final dayLabel = days == 1 ? 'day' : 'days';
    if (remainingHours == 0) {
      return '$days $dayLabel';
    }

    final hourLabel = remainingHours == 1 ? 'hour' : 'hours';
    return '$days $dayLabel $remainingHours $hourLabel';
  }

  static String formatCompact(int hours) {
    if (hours <= 0) return '—';

    final days = hours ~/ 24;
    final remainingHours = hours % 24;

    if (days == 0) return '${hours}h';
    if (remainingHours == 0) return '${days}d';
    return '${days}d ${remainingHours}h';
  }
}
