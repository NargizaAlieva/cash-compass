import 'package:intl/intl.dart';

final _moneyFormat = NumberFormat('#,##0.##', 'en_US');

/// 1234567.5 -> "1 234 567.5 ₸"
String formatMoney(double amount) =>
    '${_moneyFormat.format(amount).replaceAll(',', ' ')} ₸';

/// Reads what the user typed. Accepts "15 000", "1500,50" and "1500.50".
double? parseAmount(String text) =>
    double.tryParse(text.replaceAll(' ', '').replaceAll(',', '.'));

/// "Today", "Yesterday", "10 Nov" (this year) or "10 Nov 2025".
String formatDay(DateTime day, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final date = DateTime(day.year, day.month, day.day);

  if (date == today) {
    return 'Today';
  }
  if (date == DateTime(today.year, today.month, today.day - 1)) {
    return 'Yesterday';
  }
  final pattern = date.year == today.year ? 'd MMM' : 'd MMM yyyy';
  return DateFormat(pattern).format(date);
}