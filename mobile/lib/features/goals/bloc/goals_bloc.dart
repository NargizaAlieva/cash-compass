import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/goals/bloc/goals_event.dart';
import 'package:cash_compass/features/goals/bloc/goals_state.dart';
import 'package:cash_compass/features/goals/data/goals_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'goals_event.dart';
export 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  GoalsBloc(this._repository) : super(const GoalsState()) {
    on<GoalsRequested>((event, emit) async {
      emit(state.copyWith(status: GoalsStatus.loading));
      await _load(emit);
    });
    on<GoalAdded>(
      (event, emit) =>
          _changeAndReload(emit, () => _repository.create(event.draft)),
    );
    on<GoalUpdated>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.update(event.id, event.draft),
      ),
    );
    on<GoalDeleted>(
      (event, emit) =>
          _changeAndReload(emit, () => _repository.delete(event.id)),
    );
  }

  final GoalsRepository _repository;

  Future<void> _changeAndReload(
    Emitter<GoalsState> emit,
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

  Future<void> _load(Emitter<GoalsState> emit) async {
    try {
      final overview = await _repository.fetchGoals();
      emit(
        state.copyWith(
          status: GoalsStatus.success,
          goals: overview.goals,
          monthlySaving: overview.monthlySaving,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: GoalsStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}
