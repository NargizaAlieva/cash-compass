import 'package:equatable/equatable.dart';

sealed class BudgetsEvent extends Equatable {
  const BudgetsEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) limits and spent amounts from the server.
final class BudgetsRequested extends BudgetsEvent {
  const BudgetsRequested();
}

/// Set a new limit for a category, or change the existing one.
final class BudgetLimitSet extends BudgetsEvent {
  const BudgetLimitSet({required this.categoryId, required this.amount});

  final int categoryId;
  final double amount;

  @override
  List<Object?> get props => [categoryId, amount];
}

final class BudgetLimitRemoved extends BudgetsEvent {
  const BudgetLimitRemoved(this.categoryId);

  final int categoryId;

  @override
  List<Object?> get props => [categoryId];
}