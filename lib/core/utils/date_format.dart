import 'package:intl/intl.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';

class DateFormatUtil {
  static final DateFormat _dateFormat = DateFormat(
    AppConstants.dateFormat,
    'id_ID',
  );
  static final DateFormat _timeFormat = DateFormat(
    AppConstants.timeFormat,
    'id_ID',
  );
  static final DateFormat _dateTimeFormat = DateFormat(
    AppConstants.dateTimeFormat,
    'id_ID',
  );
  static final DateFormat _receiptFormat = DateFormat(
    AppConstants.receiptDateFormat,
    'id_ID',
  );
  static final DateFormat _isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatForReceipt(DateTime date) {
    return _receiptFormat.format(date);
  }

  static String formatIso(DateTime date) {
    return _isoFormat.format(date);
  }

  static DateTime? parseIso(String dateString) {
    try {
      return _isoFormat.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}