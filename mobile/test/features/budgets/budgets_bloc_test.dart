import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/budgets/bloc/budgets_bloc.dart';
import 'package:cash_compass/features/budgets/data/budget.dart';
import 'package:cash_compass/features/budgets/data/budgets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

const food = BudgetStatus(
  categoryId: 1,
  limitAmount: 40000,
  spent: 36000,
  remaining: 4000,
  percent: 90,
  level: BudgetLevel.warning,
);
const transport = BudgetStatus(
  categoryId: 3,
  limitAmount: 10000,
  spent: 2000,
  remaining: 8000,
  percent: 20,
  level: BudgetLevel.ok,
);

BudgetsOverview overviewOf(List<BudgetStatus> items) => BudgetsOverview(
      month: '2026-11',
      items: items,
      totalLimit: 0,
      totalSpent: 0,
    );

void main() {
  late MockBudgetsRepository repository;

  setUp(() {
    repository = MockBudgetsRepository();
  });

  test('BudgetStatus.fromJson reads the server format', () {
    final status = BudgetStatus.fromJson({
      'category_id': 1,
      'limit_amount': 10000,
      'spent': 12500,
      'remaining': -2500,
      'percent': 125.0,
      'level': 'over',
    });
    expect(status.level, BudgetLevel.over);
    expect(status.remaining, -2500.0);
  });

  test('state helpers find a limit and the alerts', () {
    const state = BudgetsState(items: [food, transport]);
    expect(state.forCategory(3), transport);
    expect(state.forCategory(99), isNull);
    expect(state.alerts, [food]);
  });

  blocTest<BudgetsBloc, BudgetsState>(
    'BudgetsRequested loads the limits',
    build: () {
      when(() => repository.fetchOverview())
          .thenAnswer((_) async => overviewOf([food, transport]));
      return BudgetsBloc(repository);
    },
    act: (bloc) => bloc.add(const BudgetsRequested()),
    expect: () => [
      const BudgetsState(status: BudgetsStatus.loading),
      const BudgetsState(
        status: BudgetsStatus.success,
        items: [food, transport],
      ),
    ],
  );

  blocTest<BudgetsBloc, BudgetsState>(
    'BudgetLimitSet saves and reloads',
    build: () {
      when(() => repository.setLimit(3, 10000)).thenAnswer((_) async {});
      when(() => repository.fetchOverview())
          .thenAnswer((_) async => overviewOf([food, transport]));
      return BudgetsBloc(repository);
    },
    seed: () =>
        const BudgetsState(status: BudgetsStatus.success, items: [food]),
    act: (bloc) =>
        bloc.add(const BudgetLimitSet(categoryId: 3, amount: 10000)),
    expect: () => [
      const BudgetsState(
        status: BudgetsStatus.success,
        items: [food, transport],
      ),
    ],
    verify: (_) => verify(() => repository.setLimit(3, 10000)).called(1),
  );

  blocTest<BudgetsBloc, BudgetsState>(
    'BudgetLimitSet shows the server error',
    build: () {
      when(() => repository.setLimit(any(), any())).thenThrow(
        const ApiException(
          'Limits can be set only for expense categories',
          statusCode: 422,
        ),
      );
      return BudgetsBloc(repository);
    },
    seed: () => const BudgetsState(status: BudgetsStatus.success),
    act: (bloc) =>
        bloc.add(const BudgetLimitSet(categoryId: 11, amount: 1000)),
    expect: () => [
      const BudgetsState(
        status: BudgetsStatus.success,
        errorMessage: 'Limits can be set only for expense categories',
      ),
    ],
  );

  blocTest<BudgetsBloc, BudgetsState>(
    'BudgetLimitRemoved removes and reloads',
    build: () {
      when(() => repository.removeLimit(1)).thenAnswer((_) async {});
      when(() => repository.fetchOverview())
          .thenAnswer((_) async => overviewOf([transport]));
      return BudgetsBloc(repository);
    },
    seed: () => const BudgetsState(
      status: BudgetsStatus.success,
      items: [food, transport],
    ),
    act: (bloc) => bloc.add(const BudgetLimitRemoved(1)),
    expect: () => [
      const BudgetsState(status: BudgetsStatus.success, items: [transport]),
    ],
  );
}