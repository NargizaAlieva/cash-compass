import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/recurring/bloc/recurring_event.dart';
import 'package:cash_compass/features/recurring/bloc/recurring_state.dart';
import 'package:cash_compass/features/recurring/data/recurring_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'recurring_event.dart';
export 'recurring_state.dart';

class RecurringBloc extends Bloc<RecurringEvent, RecurringState> {
  RecurringBloc(this._repository) : super(const RecurringState()) {
    on<RecurringRequested>((event, emit) async {
      emit(state.copyWith(status: RecurringStatus.loading));
      await _load(emit);
    });
    on<RecurringAdded>(
      (event, emit) => _changeAndReload(emit, () => _repository.create(event.draft)),
    );
    on<RecurringUpdated>(
      (event, emit) =>
          _changeAndReload(emit, () => _repository.update(event.id, event.draft)),
    );
    on<RecurringToggled>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.setActive(event.id, isActive: event.isActive),
      ),
    );
    on<RecurringDeleted>(
      (event, emit) => _changeAndReload(emit, () => _repository.delete(event.id)),
    );
  }

  final RecurringRepository _repository;

  Future<void> _changeAndReload(
    Emitter<RecurringState> emit,
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

  Future<void> _load(Emitter<RecurringState> emit, {int? changeCount}) async {
    try {
      final summary = await _repository.fetchAll();
      emit(
        state.copyWith(
          status: RecurringStatus.success,
          payments: summary.items,
          monthlyTotal: summary.monthlyTotal,
          yearlyTotal: summary.yearlyTotal,
          changeCount: changeCount,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: RecurringStatus.failure,
          changeCount: changeCount,
          errorMessage: error.message,
        ),
      );
    }
  }
}
