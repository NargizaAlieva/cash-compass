import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Anomaly.fromJson reads a single purchase', () {
    final anomaly = Anomaly.fromJson({
      'kind': 'purchase',
      'category_id': 3,
      'transaction_id': 42,
      'date': '2026-11-05',
      'amount': 6500,
      'usual': 1500,
      'times': 4.3,
    });
    expect(anomaly.isPurchase, isTrue);
    expect(anomaly.date, DateTime(2026, 11, 5));
    expect(anomaly.times, 4.3);
  });

  test('Anomaly.fromJson reads a category spike without a date', () {
    final anomaly = Anomaly.fromJson({
      'kind': 'category',
      'category_id': 5,
      'transaction_id': null,
      'date': null,
      'amount': 16000,
      'usual': 5000,
      'times': 3.2,
    });
    expect(anomaly.isPurchase, isFalse);
    expect(anomaly.date, isNull);
  });
}
