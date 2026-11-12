import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/features/goals/data/goal.dart';

class GoalsRepository {
  GoalsRepository(this._api);

  final ApiClient _api;

  Future<GoalsOverview> fetchGoals() async {
    final data = await _api.get('/goals');
    return GoalsOverview.fromJson(data as Map<String, dynamic>);
  }

  Future<void> create(GoalDraft draft) =>
      _api.post('/goals', data: draft.toJson());

  Future<void> update(int id, GoalDraft draft) =>
      _api.put('/goals/$id', data: draft.toJson());

  Future<void> delete(int id) => _api.delete('/goals/$id');
}
