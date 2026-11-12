import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/analytics/bloc/analytics_event.dart';
import 'package:cash_compass/features/analytics/bloc/analytics_state.dart';
import 'package:cash_compass/features/analytics/data/analytics_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'analytics_event.dart';
export 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  /// [now] can be replaced in tests. The app always uses the real time.
  AnalyticsBloc(this._repository, {DateTime? now})
      : super(AnalyticsState(month: _firstDay(now ?? DateTime.now()))) {
    on<AnalyticsRequested>((event, emit) => _load(emit));
    on<AnalyticsMonthShifted>(_onMonthShifted);
  }

  final AnalyticsRepository _repository;

  static DateTime _firstDay(DateTime date) => DateTime(date.year, date.month);

  Future<void> _onMonthShifted(
    AnalyticsMonthShifted event,
    Emitter<AnalyticsState> emit,
  ) async {
    // DateTime handles month 0 and 13 itself: (2026, 0) = December 2025
    final month = DateTime(state.month.year, state.month.month + event.offset);
    emit(state.copyWith(month: month));
    await _load(emit);
  }

  Future<void> _load(Emitter<AnalyticsState> emit) async {
    emit(state.copyWith(status: AnalyticsStatus.loading));
    final month = state.month;
    try {
      final data = await _repository.fetchMonth(month);
      // The user may have switched to another month while we were waiting
      if (state.month != month) {
        return;
      }
      emit(state.copyWith(status: AnalyticsStatus.success, data: data));
    } on ApiException catch (error) {
      if (state.month != month) {
        return;
      }
      emit(
        state.copyWith(
          status: AnalyticsStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}