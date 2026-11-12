import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/features/budgets/data/budget.dart';

class BudgetsRepository {
  BudgetsRepository(this._api);

  final ApiClient _api;

  /// Limits with spent amounts for the current month.
  Future<BudgetsOverview> fetchOverview() async {
    final data = await _api.get('/budgets');
    return BudgetsOverview.fromJson(data as Map<String, dynamic>);
  }

  /// Creates the limit, or changes it if the category already has one.
  Future<void> setLimit(int categoryId, double amount) =>
      _api.put('/budgets/$categoryId', data: {'limit_amount': amount});

  Future<void> removeLimit(int categoryId) =>
      _api.delete('/budgets/$categoryId');
}