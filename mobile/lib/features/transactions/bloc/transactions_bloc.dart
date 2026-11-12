import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/transactions/bloc/transactions_event.dart';
import 'package:cash_compass/features/transactions/bloc/transactions_state.dart';
import 'package:cash_compass/features/transactions/data/transactions_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'transactions_event.dart';
export 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc(this._repository) : super(const TransactionsState()) {
    on<TransactionsRequested>(_onRequested);
    on<TransactionsFilterChanged>(
      // Filtering happens on the phone, no request to the server
      (event, emit) => emit(state.copyWith(kindFilter: () => event.kind)),
    );
    on<TransactionAdded>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.createTransaction(event.draft),
      ),
    );
    on<TransactionUpdated>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.updateTransaction(event.id, event.draft),
      ),
    );
    on<TransactionDeleted>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.deleteTransaction(event.id),
      ),
    );
  }

  final TransactionsRepository _repository;

  Future<void> _onRequested(
    TransactionsRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(status: TransactionsStatus.loading));
    await _load(emit);
  }

  /// Sends a change to the server, then reloads the list.
  Future<void> _changeAndReload(
    Emitter<TransactionsState> emit,
    Future<void> Function() change,
  ) async {
    emit(state.copyWith()); // clears the previous error
    try {
      await change();
    } on ApiException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
      return;
    }
    await _load(emit, changeCount: state.changeCount + 1);
  }

  Future<void> _load(
    Emitter<TransactionsState> emit, {
    int? changeCount,
  }) async {
    try {
      final transactions = await _repository.fetchTransactions();
      emit(
        state.copyWith(
          status: TransactionsStatus.success,
          transactions: transactions,
          changeCount: changeCount,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          changeCount: changeCount,
          errorMessage: error.message,
        ),
      );
    }
  }
}