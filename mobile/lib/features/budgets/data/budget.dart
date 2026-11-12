import 'package:equatable/equatable.dart';

/// ok: below 80%, warning: 80-99%, over: 100% and more.
enum BudgetLevel { ok, warning, over }

/// One category limit and how much of it is spent this month.
class BudgetStatus extends Equatable {
  const BudgetStatus({
    required this.categoryId,
    required this.limitAmount,
    required this.spent,
    required this.remaining,
    required this.percent,
    required this.level,
  });

  factory BudgetStatus.fromJson(Map<String, dynamic> json) => BudgetStatus(
        categoryId: json['category_id'] as int,
        limitAmount: (json['limit_amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        remaining: (json['remaining'] as num).toDouble(),
        percent: (json['percent'] as num).toDouble(),
        level: BudgetLevel.values.byName(json['level'] as String),
      );

  final int categoryId;
  final double limitAmount;
  final double spent;

  /// Negative when the limit is exceeded.
  final double remaining;

  /// 0-100 and more, e.g. 85.5
  final double percent;
  final BudgetLevel level;

  @override
  List<Object?> get props =>
      [categoryId, limitAmount, spent, remaining, percent, level];
}

/// Response of GET /budgets.
class BudgetsOverview extends Equatable {
  const BudgetsOverview({
    required this.month,
    required this.items,
    required this.totalLimit,
    required this.totalSpent,
  });

  factory BudgetsOverview.fromJson(Map<String, dynamic> json) =>
      BudgetsOverview(
        month: json['month'] as String,
        items: (json['items'] as List<dynamic>)
            .map((item) => BudgetStatus.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalLimit: (json['total_limit'] as num).toDouble(),
        totalSpent: (json['total_spent'] as num).toDouble(),
      );

  final String month;

  /// Sorted by the server: the most used limit first.
  final List<BudgetStatus> items;
  final double totalLimit;
  final double totalSpent;

  @override
  List<Object?> get props => [month, items, totalLimit, totalSpent];
}