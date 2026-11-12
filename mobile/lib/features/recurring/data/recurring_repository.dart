import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/features/recurring/data/recurring_payment.dart';

class RecurringRepository {
  RecurringRepository(this._api);

  final ApiClient _api;

  Future<RecurringSummary> fetchAll() async {
    final data = await _api.get('/recurring');
    return RecurringSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<void> create(RecurringDraft draft) =>
      _api.post('/recurring', data: draft.toJson());

  Future<void> update(int id, RecurringDraft draft) =>
      _api.put('/recurring/$id', data: draft.toJson());

  /// Pause (false) or resume (true) a payment.
  Future<void> setActive(int id, {required bool isActive}) =>
      _api.put('/recurring/$id', data: {'is_active': isActive});

  Future<void> delete(int id) => _api.delete('/recurring/$id');
}
