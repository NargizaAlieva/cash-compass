import 'package:intl/intl.dart';

final _moneyFormat = NumberFormat('#,##0.##', 'en_US');

/// 1234567.5 -> "1 234 567.5 ₸"
String formatMoney(double amount) =>
    '${_moneyFormat.format(amount).replaceAll(',', ' ')} ₸';