import 'package:equatable/equatable.dart';

double _toDouble(Object? value) => (value as num).toDouble();

/// How much was spent in one category.
class CategoryAmount extends Equatable {
  const CategoryAmount({
    required this.categoryId,
    required this.amount,
    required this.percent,
  });

  factory CategoryAmount.fromJson(Map<String, dynamic> json) => CategoryAmount(
        categoryId: json['category_id'] as int?,
        amount: _toDouble(json['amount']),
        percent: _toDouble(json['percent']),
      );

  /// null = expense without a category.
  final int? categoryId;
  final double amount;
  final double percent;

  @override
  List<Object?> get props => [categoryId, amount, percent];
}

/// Expenses of one day.
class DayAmount extends Equatable {
  const DayAmount({required this.date, required this.expense});

  factory DayAmount.fromJson(Map<String, dynamic> json) => DayAmount(
        date: DateTime.parse(json['date'] as String),
        expense: _toDouble(json['expense']),
      );

  final DateTime date;
  final double expense;

  @override
  List<Object?> get props => [date, expense];
}

/// This month vs the previous month for one category.
class CategoryChange extends Equatable {
  const CategoryChange({
    required this.categoryId,
    required this.current,
    required this.previous,
    required this.change,
  });

  factory CategoryChange.fromJson(Map<String, dynamic> json) => CategoryChange(
        categoryId: json['category_id'] as int?,
        current: _toDouble(json['current']),
        previous: _toDouble(json['previous']),
        change: _toDouble(json['change']),
      );

  final int? categoryId;
  final double current;
  final double previous;

  /// current - previous. Negative = spent less than last month.
  final double change;

  @override
  List<Object?> get props => [categoryId, current, previous, change];
}

/// "Wanted it" purchases.
class ImpulseStats extends Equatable {
  const ImpulseStats({
    required this.amount,
    required this.count,
    required this.percent,
  });

  factory ImpulseStats.fromJson(Map<String, dynamic> json) => ImpulseStats(
        amount: _toDouble(json['amount']),
        count: json['count'] as int,
        percent: _toDouble(json['percent']),
      );

  final double amount;
  final int count;
  final double percent;

  @override
  List<Object?> get props => [amount, count, percent];
}

/// Response of GET /analytics/month.
class MonthAnalytics extends Equatable {
  const MonthAnalytics({
    required this.month,
    required this.income,
    required this.expense,
    required this.net,
    required this.avgDailyExpense,
    required this.forecastExpense,
    required this.previousExpense,
    required this.expenseChangePercent,
    required this.byCategory,
    required this.daily,
    required this.categoryChanges,
    required this.impulse,
  });

  factory MonthAnalytics.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List<dynamic>)
            .map((item) => parse(item as Map<String, dynamic>))
            .toList();

    return MonthAnalytics(
      month: json['month'] as String,
      income: _toDouble(json['income']),
      expense: _toDouble(json['expense']),
      net: _toDouble(json['net']),
      avgDailyExpense: _toDouble(json['avg_daily_expense']),
      forecastExpense: (json['forecast_expense'] as num?)?.toDouble(),
      previousExpense: _toDouble(json['previous_expense']),
      expenseChangePercent:
          (json['expense_change_percent'] as num?)?.toDouble(),
      byCategory: list('by_category', CategoryAmount.fromJson),
      daily: list('daily', DayAmount.fromJson),
      categoryChanges: list('category_changes', CategoryChange.fromJson),
      impulse: ImpulseStats.fromJson(json['impulse'] as Map<String, dynamic>),
    );
  }

  final String month;
  final double income;
  final double expense;
  final double net;
  final double avgDailyExpense;

  /// Only for the current month.
  final double? forecastExpense;
  final double previousExpense;

  /// null when the previous month had no expenses.
  final double? expenseChangePercent;

  /// Biggest category first.
  final List<CategoryAmount> byCategory;

  /// Every day of the month, also days with 0.
  final List<DayAmount> daily;

  /// Biggest change first.
  final List<CategoryChange> categoryChanges;
  final ImpulseStats impulse;

  @override
  List<Object?> get props => [
        month,
        income,
        expense,
        net,
        avgDailyExpense,
        forecastExpense,
        previousExpense,
        expenseChangePercent,
        byCategory,
        daily,
        categoryChanges,
        impulse,
      ];
}