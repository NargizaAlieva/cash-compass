import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/features/goals/bloc/goals_bloc.dart';
import 'package:cash_compass/features/goals/data/goal.dart';
import 'package:cash_compass/features/goals/data/goals_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalsRepository extends Mock implements GoalsRepository {}

final overview = GoalsOverview.fromJson({
  'monthly_saving': 30000,
  'goals': [
    {
      'id': 1,
      'name': 'Laptop',
      'target_amount': 400000,
      'saved_amount': 100000,
      'percent': 25.0,
      'achieved': false,
      'months_left': 10,
      'forecast_date': '2027-09-01',
    },
  ],
});

const draft = GoalDraft(name: 'Laptop', targetAmount: 400000, savedAmount: 0);

void main() {
  late MockGoalsRepository repository;

  setUpAll(() => registerFallbackValue(draft));
  setUp(() => repository = MockGoalsRepository());

  test('Goal.fromJson and remaining', () {
    final goal = overview.goals.single;
    expect(goal.forecastDate, DateTime(2027, 9));
    expect(goal.remaining, 300000);
  });

  test('monthsToCollect is the what-if math', () {
    expect(monthsToCollect(300000, 30000), 10);
    expect(monthsToCollect(300000, 40000), 8); // 7.5 -> 8 months
    expect(monthsToCollect(300000, 0), isNull); // no saving, no forecast
    expect(monthsToCollect(0, 0), 0); // already reached
  });

  blocTest<GoalsBloc, GoalsState>(
    'GoalsRequested loads goals and the saving pace',
    build: () {
      when(() => repository.fetchGoals()).thenAnswer((_) async => overview);
      return GoalsBloc(repository);
    },
    act: (bloc) => bloc.add(const GoalsRequested()),
    expect: () => [
      const GoalsState(status: GoalsStatus.loading),
      GoalsState(
        status: GoalsStatus.success,
        goals: overview.goals,
        monthlySaving: 30000,
      ),
    ],
  );

  blocTest<GoalsBloc, GoalsState>(
    'GoalAdded saves and reloads',
    build: () {
      when(() => repository.create(any())).thenAnswer((_) async {});
      when(() => repository.fetchGoals()).thenAnswer((_) async => overview);
      return GoalsBloc(repository);
    },
    act: (bloc) => bloc.add(const GoalAdded(draft)),
    verify: (_) {
      verify(() => repository.create(draft)).called(1);
      verify(() => repository.fetchGoals()).called(1);
    },
  );
}
