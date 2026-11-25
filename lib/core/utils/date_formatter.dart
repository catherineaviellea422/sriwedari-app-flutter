import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _monthsFull = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static DateTime? tryParse(String raw) {
    if (raw.trim().isEmpty) return null;
    final normalized = raw.trim().replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  static String formatShortDate(String raw) {
    final dt = tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day} ${_monthsShort[dt.month - 1]} ${dt.year}';
  }

  static String formatFullDate(String raw) {
    final dt = tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day} ${_monthsFull[dt.month - 1]} ${dt.year}';
  }

  static String formatDateTime(String raw) {
    final dt = tryParse(raw);
    if (dt == null) return raw;
    final timeStr = DateFormat('HH:mm').format(dt);
    return '${formatShortDate(raw)}, $timeStr WIB';
  }

  static ({String day, String month, String year}) splitBadgeDate(String raw) {
    final dt = tryParse(raw);
    if (dt == null) {
      return (day: '--', month: '---', year: '----');
    }
    return (
      day: dt.day.toString().padLeft(2, '0'),
      month: _monthsShort[dt.month - 1],
      year: dt.year.toString(),
    );
  }
}
