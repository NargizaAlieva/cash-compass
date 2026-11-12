import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Transaction.fromJson reads the server format', () {
    final transaction = Transaction.fromJson({
      'id': 7,
      'kind': 'transfer',
      'amount': 5000,
      'account_id': 1,
      'to_account_id': 2,
      'category_id': null,
      'date': '2026-11-10',
      'note': '',
      'is_impulsive': false,
    });
    expect(transaction.kind, TransactionKind.transfer);
    expect(transaction.amount, 5000.0);
    expect(transaction.toAccountId, 2);
    expect(transaction.date, DateTime(2026, 11, 10));
  });

  test('TransactionDraft.toJson sends the date as yyyy-MM-dd', () {
    final draft = TransactionDraft(
      kind: TransactionKind.expense,
      amount: 99.5,
      accountId: 1,
      categoryId: 3,
      date: DateTime(2026, 3, 7),
      isImpulsive: true,
    );
    expect(draft.toJson(), {
      'kind': 'expense',
      'amount': 99.5,
      'account_id': 1,
      'to_account_id': null,
      'category_id': 3,
      'date': '2026-03-07',
      'note': '',
      'is_impulsive': true,
    });
  });

  test('formatDay shows Today, Yesterday or the date', () {
    final now = DateTime(2026, 11, 12, 15, 30);
    expect(formatDay(DateTime(2026, 11, 12), now: now), 'Today');
    expect(formatDay(DateTime(2026, 11, 11), now: now), 'Yesterday');
    expect(formatDay(DateTime(2026, 11, 1), now: now), '1 Nov');
    expect(formatDay(DateTime(2025, 12, 31), now: now), '31 Dec 2025');
  });

  test('parseAmount accepts spaces and commas', () {
    expect(parseAmount('15 000'), 15000);
    expect(parseAmount('99,5'), 99.5);
    expect(parseAmount('abc'), isNull);
  });
}