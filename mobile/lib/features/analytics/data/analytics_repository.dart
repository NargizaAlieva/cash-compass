import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:intl/intl.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._api);

  final ApiClient _api;

  /// [month] is any day of the month we want, e.g. DateTime(2026, 11).
  Future<MonthAnalytics> fetchMonth(DateTime month) async {
    final data = await _api.get(
      '/analytics/month',
      query: {'month': DateFormat('yyyy-MM').format(month)},
    );
    return MonthAnalytics.fromJson(data as Map<String, dynamic>);
  }
}