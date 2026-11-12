import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/stipend/bloc/stipend_event.dart';
import 'package:cash_compass/features/stipend/bloc/stipend_state.dart';
import 'package:cash_compass/features/stipend/data/stipend_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'stipend_event.dart';
export 'stipend_state.dart';

class StipendBloc extends Bloc<StipendEvent, StipendState> {
  StipendBloc(this._repository) : super(const StipendState()) {
    on<StipendRequested>(_onRequested);
  }

  final StipendRepository _repository;

  Future<void> _onRequested(
    StipendRequested event,
    Emitter<StipendState> emit,
  ) async {
    emit(state.copyWith(status: StipendStatus.loading));
    try {
      final allowance = await _repository.fetchAllowance();
      emit(state.copyWith(status: StipendStatus.success, allowance: allowance));
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: StipendStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}