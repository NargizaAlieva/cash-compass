import 'package:equatable/equatable.dart';

sealed class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Load the month that is selected now (also used to refresh it).
final class AnalyticsRequested extends AnalyticsEvent {
  const AnalyticsRequested();
}

/// The user pressed ‹ or ›. [offset] is -1 (previous) or 1 (next month).
final class AnalyticsMonthShifted extends AnalyticsEvent {
  const AnalyticsMonthShifted(this.offset);

  final int offset;

  @override
  List<Object?> get props => [offset];
}