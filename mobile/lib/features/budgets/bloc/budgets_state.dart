import 'package:cash_compass/features/budgets/data/budget.dart';
import 'package:equatable/equatable.dart';

enum BudgetsStatus { initial, loading, success, failure }

class BudgetsState extends Equatable {
  const BudgetsState({
    this.status = BudgetsStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final BudgetsStatus status;

  /// The most used limit first.
  final List<BudgetStatus> items;

  /// Error to show once (as a SnackBar).
  final String? errorMessage;

  /// The limit of one category, or null if it has no limit.
  BudgetStatus? forCategory(int categoryId) =>
      items.where((item) => item.categoryId == categoryId).firstOrNull;

  /// Limits that are almost used up or already exceeded.
  List<BudgetStatus> get alerts =>
      items.where((item) => item.level != BudgetLevel.ok).toList();

  /// Note: errorMessage is NOT copied, so every new state clears the old error.
  BudgetsState copyWith({
    BudgetsStatus? status,
    List<BudgetStatus>? items,
    String? errorMessage,
  }) {
    return BudgetsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}