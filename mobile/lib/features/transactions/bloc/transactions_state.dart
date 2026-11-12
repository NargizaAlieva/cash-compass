import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:equatable/equatable.dart';

enum TransactionsStatus { initial, loading, success, failure }

class TransactionsState extends Equatable {
  const TransactionsState({
    this.status = TransactionsStatus.initial,
    this.transactions = const [],
    this.kindFilter,
    this.changeCount = 0,
    this.errorMessage,
  });

  final TransactionsStatus status;

  /// All loaded transactions, newest first.
  final List<Transaction> transactions;

  /// null means "show all kinds".
  final TransactionKind? kindFilter;

  /// Grows by 1 after every successful add/update/delete.
  /// Other Blocs listen to it to know that balances changed.
  final int changeCount;

  /// Error to show once (as a SnackBar).
  final String? errorMessage;

  List<Transaction> get visibleTransactions => kindFilter == null
      ? transactions
      : transactions.where((t) => t.kind == kindFilter).toList();

  /// Note: errorMessage is NOT copied, so every new state clears the old error.
  /// kindFilter is passed as a function so it can also be set to null.
  TransactionsState copyWith({
    TransactionsStatus? status,
    List<Transaction>? transactions,
    TransactionKind? Function()? kindFilter,
    int? changeCount,
    String? errorMessage,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      kindFilter: kindFilter != null ? kindFilter() : this.kindFilter,
      changeCount: changeCount ?? this.changeCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, transactions, kindFilter, changeCount, errorMessage];
}