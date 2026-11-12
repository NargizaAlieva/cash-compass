import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:equatable/equatable.dart';

enum AnalyticsStatus { initial, loading, success, failure }

class AnalyticsState extends Equatable {
  const AnalyticsState({
    required this.month,
    this.status = AnalyticsStatus.initial,
    this.data,
    this.errorMessage,
  });

  /// First day of the selected month, e.g. 2026-11-01.
  final DateTime month;
  final AnalyticsStatus status;

  /// null until the first successful load.
  final MonthAnalytics? data;

  /// Error to show once (as a SnackBar).
  final String? errorMessage;

  /// Cannot go to the future: there is nothing to analyze there.
  bool isCurrentMonth(DateTime now) =>
      month.year == now.year && month.month == now.month;

  /// Note: errorMessage is NOT copied, so every new state clears the old error.
  AnalyticsState copyWith({
    DateTime? month,
    AnalyticsStatus? status,
    MonthAnalytics? data,
    String? errorMessage,
  }) {
    return AnalyticsState(
      month: month ?? this.month,
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [month, status, data, errorMessage];
}