import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/features/accounts/data/account.dart';

class AccountsRepository {
  AccountsRepository(this._api);

  final ApiClient _api;

  Future<AccountsSummary> fetchAccounts() async {
    final data = await _api.get('/accounts');
    return AccountsSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<void> createAccount({
    required String name,
    required AccountType type,
    required double balance,
  }) =>
      _api.post(
        '/accounts',
        data: {'name': name, 'type': type.name, 'balance': balance},
      );

  Future<void> updateAccount(
    int id, {
    required String name,
    required AccountType type,
  }) =>
      _api.put('/accounts/$id', data: {'name': name, 'type': type.name});

  Future<void> deleteAccount(int id) => _api.delete('/accounts/$id');
}