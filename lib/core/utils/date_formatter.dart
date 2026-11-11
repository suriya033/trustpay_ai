import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatWithTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatShort(date);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
