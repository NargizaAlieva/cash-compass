import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/features/stipend/data/stipend_allowance.dart';

class StipendRepository {
  StipendRepository(this._api);

  final ApiClient _api;

  Future<StipendAllowance> fetchAllowance() async {
    final data = await _api.get('/stipend/allowance');
    return StipendAllowance.fromJson(data as Map<String, dynamic>);
  }
}