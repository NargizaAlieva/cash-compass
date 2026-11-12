import 'package:equatable/equatable.dart';

double? _toDouble(Object? value) => (value as num?)?.toDouble();

/// Response of GET /stipend/allowance.
/// When [configured] is false, all other fields are null.
class StipendAllowance extends Equatable {
  const StipendAllowance({
    required this.configured,
    this.stipendDay,
    this.nextStipendDate,
    this.daysLeft,
    this.balance,
    this.dailyAllowance,
    this.spentToday,
    this.leftToday,
  });

  factory StipendAllowance.fromJson(Map<String, dynamic> json) {
    final next = json['next_stipend_date'] as String?;
    return StipendAllowance(
      configured: json['configured'] as bool,
      stipendDay: json['stipend_day'] as int?,
      nextStipendDate: next == null ? null : DateTime.parse(next),
      daysLeft: json['days_left'] as int?,
      balance: _toDouble(json['balance']),
      dailyAllowance: _toDouble(json['daily_allowance']),
      spentToday: _toDouble(json['spent_today']),
      leftToday: _toDouble(json['left_today']),
    );
  }

  final bool configured;
  final int? stipendDay;
  final DateTime? nextStipendDate;

  /// Today is counted, the stipend day is not.
  final int? daysLeft;
  final double? balance;

  /// What can be spent each day until the stipend.
  final double? dailyAllowance;
  final double? spentToday;

  /// Negative when today's spending is over the daily allowance.
  final double? leftToday;

  @override
  List<Object?> get props => [
        configured,
        stipendDay,
        nextStipendDate,
        daysLeft,
        balance,
        dailyAllowance,
        spentToday,
        leftToday,
      ];
}