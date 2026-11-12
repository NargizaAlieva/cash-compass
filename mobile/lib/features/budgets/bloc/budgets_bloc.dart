import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/budgets/bloc/budgets_event.dart';
import 'package:cash_compass/features/budgets/bloc/budgets_state.dart';
import 'package:cash_compass/features/budgets/data/budgets_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'budgets_event.dart';
export 'budgets_state.dart';

class BudgetsBloc extends Bloc<BudgetsEvent, BudgetsState> {
  BudgetsBloc(this._repository) : super(const BudgetsState()) {
    on<BudgetsRequested>(_onRequested);
    on<BudgetLimitSet>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.setLimit(event.categoryId, event.amount),
      ),
    );
    on<BudgetLimitRemoved>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.removeLimit(event.categoryId),
      ),
    );
  }

  final BudgetsRepository _repository;

  Future<void> _onRequested(
    BudgetsRequested event,
    Emitter<BudgetsState> emit,
  ) async {
    emit(state.copyWith(status: BudgetsStatus.loading));
    await _load(emit);
  }

  /// Sends a change to the server, then reloads the limits.
  Future<void> _changeAndReload(
    Emitter<BudgetsState> emit,
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

  Future<void> _load(Emitter<BudgetsState> emit) async {
    try {
      final overview = await _repository.fetchOverview();
      emit(
        state.copyWith(status: BudgetsStatus.success, items: overview.items),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: BudgetsStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}