import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/recurring/bloc/recurring_bloc.dart';
import 'package:cash_compass/features/recurring/data/recurring_payment.dart';
import 'package:cash_compass/features/recurring/data/recurring_repository.dart';
import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringRepository extends Mock implements RecurringRepository {}

final spotify = RecurringPayment.fromJson({
  'id': 1,
  'name': 'Spotify',
  'amount': 1990,
  'account_id': 1,
  'category_id': 9,
  'day_of_month': 3,
  'next_date': '2026-12-03',
  'is_active': true,
});

const draft = RecurringDraft(
  name: 'Spotify',
  amount: 1990,
  accountId: 1,
  categoryId: 9,
  dayOfMonth: 3,
);

final summary = RecurringSummary(
  items: [spotify],
  monthlyTotal: 1990,
  yearlyTotal: 23880,
);

void main() {
  late MockRecurringRepository repository;

  setUpAll(() {
    registerFallbackValue(draft);
  });

  setUp(() {
    repository = MockRecurringRepository();
  });

  test('models read and write the server format', () {
    expect(spotify.nextDate, DateTime(2026, 12, 3));
    expect(draft.toJson(), {
      'name': 'Spotify',
      'amount': 1990.0,
      'account_id': 1,
      'category_id': 9,
      'day_of_month': 3,
    });
    final transaction = Transaction.fromJson({
      'id': 5,
      'kind': 'expense',
      'amount': 1990,
      'account_id': 1,
      'to_account_id': null,
      'category_id': 9,
      'date': '2026-11-03',
      'note': 'Spotify',
      'is_impulsive': false,
      'recurring_payment_id': 1,
    });
    expect(transaction.recurringPaymentId, 1);
  });

  blocTest<RecurringBloc, RecurringState>(
    'RecurringRequested loads payments and totals',
    build: () {
      when(() => repository.fetchAll()).thenAnswer((_) async => summary);
      return RecurringBloc(repository);
    },
    act: (bloc) => bloc.add(const RecurringRequested()),
    expect: () => [
      const RecurringState(status: RecurringStatus.loading),
      RecurringState(
        status: RecurringStatus.success,
        payments: [spotify],
        monthlyTotal: 1990,
        yearlyTotal: 23880,
      ),
    ],
  );

  blocTest<RecurringBloc, RecurringState>(
    'RecurringAdded saves, reloads and counts a change',
    build: () {
      when(() => repository.create(any())).thenAnswer((_) async {});
      when(() => repository.fetchAll()).thenAnswer((_) async => summary);
      return RecurringBloc(repository);
    },
    seed: () => const RecurringState(status: RecurringStatus.success),
    act: (bloc) => bloc.add(const RecurringAdded(draft)),
    expect: () => [
      RecurringState(
        status: RecurringStatus.success,
        payments: [spotify],
        monthlyTotal: 1990,
        yearlyTotal: 23880,
        changeCount: 1,
      ),
    ],
    verify: (_) => verify(() => repository.create(draft)).called(1),
  );

  blocTest<RecurringBloc, RecurringState>(
    'RecurringToggled pauses the payment',
    build: () {
      when(() => repository.setActive(1, isActive: false))
          .thenAnswer((_) async {});
      when(() => repository.fetchAll()).thenAnswer((_) async => summary);
      return RecurringBloc(repository);
    },
    act: (bloc) => bloc.add(const RecurringToggled(1, isActive: false)),
    verify: (_) =>
        verify(() => repository.setActive(1, isActive: false)).called(1),
  );

  blocTest<RecurringBloc, RecurringState>(
    'shows the server error and does not count a change',
    build: () {
      when(() => repository.create(any())).thenThrow(
        const ApiException('A regular payment needs an expense category'),
      );
      return RecurringBloc(repository);
    },
    seed: () => const RecurringState(status: RecurringStatus.success),
    act: (bloc) => bloc.add(const RecurringAdded(draft)),
    expect: () => [
      const RecurringState(
        status: RecurringStatus.success,
        errorMessage: 'A regular payment needs an expense category',
      ),
    ],
  );
}
