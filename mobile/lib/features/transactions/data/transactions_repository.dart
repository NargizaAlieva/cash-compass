import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/features/transactions/data/transaction.dart';

class TransactionsRepository {
  TransactionsRepository(this._api);

  final ApiClient _api;

  /// Newest first. For now we load the last [limit] transactions.
  Future<List<Transaction>> fetchTransactions({int limit = 200}) async {
    final data =
        await _api.get('/transactions', query: {'limit': limit}) as List<dynamic>;
    return data
        .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTransaction(TransactionDraft draft) =>
      _api.post('/transactions', data: draft.toJson());

  Future<void> updateTransaction(int id, TransactionDraft draft) =>
      _api.put('/transactions/$id', data: draft.toJson());

  Future<void> deleteTransaction(int id) => _api.delete('/transactions/$id');
}