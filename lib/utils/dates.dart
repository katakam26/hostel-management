import 'package:intl/intl.dart';

/// Small date helpers shared across modules. Keeping the string formats in one
/// place avoids drift between screens that read/write the same fields.
class Dates {
  Dates._();

  /// Month key like "2026-07" used on payments and expenses.
  static String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  /// Day key like "2026-07-02" used on menus and attendance.
  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// The current month key.
  static String thisMonth() => monthKey(DateTime.now());

  /// The current day key.
  static String today() => dayKey(DateTime.now());

  /// Pretty month like "July 2026" from a "yyyy-MM" key.
  static String prettyMonth(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (y == null || m == null) return key;
    return DateFormat.yMMMM().format(DateTime(y, m));
  }
}
