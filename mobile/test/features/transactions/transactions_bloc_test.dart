import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/transactions/bloc/transactions_bloc.dart';
import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:cash_compass/features/transactions/data/transactions_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

final lunch = Transaction(
  id: 1,
  kind: TransactionKind.expense,
  amount: 2500,
  accountId: 1,
  categoryId: 1,
  date: DateTime(2026, 11, 10),
  note: 'Lunch',
  isImpulsive: true,
);
final stipend = Transaction(
  id: 2,
  kind: TransactionKind.income,
  amount: 45000,
  accountId: 1,
  categoryId: 11,
  date: DateTime(2026, 11, 5),
);
final draft = TransactionDraft(
  kind: TransactionKind.expense,
  amount: 2500,
  accountId: 1,
  categoryId: 1,
  date: DateTime(2026, 11, 10),
);

void main() {
  late MockTransactionsRepository repository;

  setUpAll(() {
    registerFallbackValue(draft);
  });

  setUp(() {
    repository = MockTransactionsRepository();
  });

  blocTest<TransactionsBloc, TransactionsState>(
    'TransactionsRequested loads transactions',
    build: () {
      when(() => repository.fetchTransactions())
          .thenAnswer((_) async => [lunch, stipend]);
      return TransactionsBloc(repository);
    },
    act: (bloc) => bloc.add(const TransactionsRequested()),
    expect: () => [
      const TransactionsState(status: TransactionsStatus.loading),
      TransactionsState(
        status: TransactionsStatus.success,
        transactions: [lunch, stipend],
      ),
    ],
  );

  blocTest<TransactionsBloc, TransactionsState>(
    'TransactionAdded saves, reloads and increases changeCount',
    build: () {
      when(() => repository.createTransaction(any())).thenAnswer((_) async {});
      when(() => repository.fetchTransactions())
          .thenAnswer((_) async => [lunch]);
      return TransactionsBloc(repository);
    },
    seed: () => const TransactionsState(status: TransactionsStatus.success),
    act: (bloc) => bloc.add(TransactionAdded(draft)),
    expect: () => [
      TransactionsState(
        status: TransactionsStatus.success,
        transactions: [lunch],
        changeCount: 1,
      ),
    ],
    verify: (_) => verify(() => repository.createTransaction(draft)).called(1),
  );

  blocTest<TransactionsBloc, TransactionsState>(
    'TransactionAdded shows the server error and does not count a change',
    build: () {
      when(() => repository.createTransaction(any())).thenThrow(
        const ApiException(
          "Category 'Stipend' is for income, not expense",
          statusCode: 422,
        ),
      );
      return TransactionsBloc(repository);
    },
    seed: () => const TransactionsState(status: TransactionsStatus.success),
    act: (bloc) => bloc.add(TransactionAdded(draft)),
    expect: () => [
      const TransactionsState(
        status: TransactionsStatus.success,
        errorMessage: "Category 'Stipend' is for income, not expense",
      ),
    ],
  );

  blocTest<TransactionsBloc, TransactionsState>(
    'TransactionDeleted deletes and reloads',
    build: () {
      when(() => repository.deleteTransaction(1)).thenAnswer((_) async {});
      when(() => repository.fetchTransactions())
          .thenAnswer((_) async => [stipend]);
      return TransactionsBloc(repository);
    },
    seed: () => TransactionsState(
      status: TransactionsStatus.success,
      transactions: [lunch, stipend],
    ),
    act: (bloc) => bloc.add(const TransactionDeleted(1)),
    expect: () => [
      TransactionsState(
        status: TransactionsStatus.success,
        transactions: [stipend],
        changeCount: 1,
      ),
    ],
  );

  blocTest<TransactionsBloc, TransactionsState>(
    'TransactionsFilterChanged filters on the phone without a request',
    build: () => TransactionsBloc(repository),
    seed: () => TransactionsState(
      status: TransactionsStatus.success,
      transactions: [lunch, stipend],
    ),
    act: (bloc) => bloc
      ..add(const TransactionsFilterChanged(TransactionKind.income))
      ..add(const TransactionsFilterChanged(null)),
    expect: () => [
      isA<TransactionsState>().having(
        (state) => state.visibleTransactions,
        'visibleTransactions',
        [stipend],
      ),
      isA<TransactionsState>().having(
        (state) => state.visibleTransactions,
        'visibleTransactions',
        [lunch, stipend],
      ),
    ],
    verify: (_) => verifyNever(() => repository.fetchTransactions()),
  );
}