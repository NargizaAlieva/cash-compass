import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:equatable/equatable.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) transactions from the server.
final class TransactionsRequested extends TransactionsEvent {
  const TransactionsRequested();
}

/// Show only one kind (expenses, income, transfers), or all if [kind] is null.
final class TransactionsFilterChanged extends TransactionsEvent {
  const TransactionsFilterChanged(this.kind);

  final TransactionKind? kind;

  @override
  List<Object?> get props => [kind];
}

final class TransactionAdded extends TransactionsEvent {
  const TransactionAdded(this.draft);

  final TransactionDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class TransactionUpdated extends TransactionsEvent {
  const TransactionUpdated(this.id, this.draft);

  final int id;
  final TransactionDraft draft;

  @override
  List<Object?> get props => [id, draft];
}

final class TransactionDeleted extends TransactionsEvent {
  const TransactionDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}