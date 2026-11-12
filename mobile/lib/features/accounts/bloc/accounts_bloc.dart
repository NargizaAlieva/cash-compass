import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/accounts/bloc/accounts_event.dart';
import 'package:cash_compass/features/accounts/bloc/accounts_state.dart';
import 'package:cash_compass/features/accounts/data/accounts_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'accounts_event.dart';
export 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc(this._repository) : super(const AccountsState()) {
    on<AccountsRequested>(_onRequested);
    on<AccountAdded>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.createAccount(
          name: event.name,
          type: event.type,
          balance: event.balance,
        ),
      ),
    );
    on<AccountUpdated>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.updateAccount(
          event.id,
          name: event.name,
          type: event.type,
        ),
      ),
    );
    on<AccountDeleted>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.deleteAccount(event.id),
      ),
    );
  }

  final AccountsRepository _repository;

  Future<void> _onRequested(
    AccountsRequested event,
    Emitter<AccountsState> emit,
  ) async {
    emit(state.copyWith(status: AccountsStatus.loading));
    await _load(emit);
  }

  /// Sends a change to the server, then reloads the list
  /// so the balances and the total are always the server's numbers.
  Future<void> _changeAndReload(
    Emitter<AccountsState> emit,
    Future<void> Function() change,
  ) async {
    emit(state.copyWith()); // clears the previous error
    try {
      await change();
    } on ApiException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
      return;
    }
    await _load(emit);
  }

  Future<void> _load(Emitter<AccountsState> emit) async {
    try {
      final summary = await _repository.fetchAccounts();
      emit(
        state.copyWith(
          status: AccountsStatus.success,
          accounts: summary.accounts,
          totalBalance: summary.totalBalance,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: AccountsStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}