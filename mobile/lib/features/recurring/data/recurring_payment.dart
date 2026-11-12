import 'package:equatable/equatable.dart';

/// A payment that repeats every month. The server charges it by itself.
class RecurringPayment extends Equatable {
  const RecurringPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    required this.dayOfMonth,
    required this.nextDate,
    required this.isActive,
  });

  factory RecurringPayment.fromJson(Map<String, dynamic> json) =>
      RecurringPayment(
        id: json['id'] as int,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        accountId: json['account_id'] as int,
        categoryId: json['category_id'] as int,
        dayOfMonth: json['day_of_month'] as int,
        nextDate: DateTime.parse(json['next_date'] as String),
        isActive: json['is_active'] as bool,
      );

  final int id;
  final String name;
  final double amount;
  final int accountId;
  final int categoryId;
  final int dayOfMonth;
  final DateTime nextDate;

  /// false = paused, not charged.
  final bool isActive;

  @override
  List<Object?> get props =>
      [id, name, amount, accountId, categoryId, dayOfMonth, nextDate, isActive];
}

/// What the user filled in the form.
class RecurringDraft extends Equatable {
  const RecurringDraft({
    required this.name,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    required this.dayOfMonth,
  });

  final String name;
  final double amount;
  final int accountId;
  final int categoryId;
  final int dayOfMonth;

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'account_id': accountId,
        'category_id': categoryId,
        'day_of_month': dayOfMonth,
      };

  @override
  List<Object?> get props => [name, amount, accountId, categoryId, dayOfMonth];
}

/// Response of GET /recurring.
class RecurringSummary extends Equatable {
  const RecurringSummary({
    required this.items,
    required this.monthlyTotal,
    required this.yearlyTotal,
  });

  factory RecurringSummary.fromJson(Map<String, dynamic> json) =>
      RecurringSummary(
        items: (json['items'] as List<dynamic>)
            .map((i) => RecurringPayment.fromJson(i as Map<String, dynamic>))
            .toList(),
        monthlyTotal: (json['monthly_total'] as num).toDouble(),
        yearlyTotal: (json['yearly_total'] as num).toDouble(),
      );

  /// The next payment first.
  final List<RecurringPayment> items;
  final double monthlyTotal;
  final double yearlyTotal;

  @override
  List<Object?> get props => [items, monthlyTotal, yearlyTotal];
}
