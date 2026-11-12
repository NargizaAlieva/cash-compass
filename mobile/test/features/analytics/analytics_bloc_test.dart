import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/analytics/bloc/analytics_bloc.dart';
import 'package:cash_compass/features/analytics/data/analytics_repository.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

/// The same JSON the server sends.
Map<String, dynamic> serverJson(String month) => {
      'month': month,
      'income': 45000,
      'expense': 40000,
      'net': 5000,
      'avg_daily_expense': 3000,
      'forecast_expense': 90000,
      'previous_expense': 30000,
      'expense_change_percent': 33.3,
      'by_category': [
        {'category_id': 1, 'amount': 20000, 'percent': 50.0},
        {'category_id': null, 'amount': 20000, 'percent': 50.0},
      ],
      'daily': [
        {'date': '$month-01', 'expense': 0},
        {'date': '$month-02', 'expense': 20000},
      ],
      'category_changes': [
        {'category_id': 1, 'current': 20000, 'previous': 10000, 'change': 10000},
      ],
      'impulse': {'amount': 15000, 'count': 2, 'percent': 37.5},
    };

final november = MonthAnalytics.fromJson(serverJson('2026-11'));
final october = MonthAnalytics.fromJson(serverJson('2026-10'));

void main() {
  late MockAnalyticsRepository repository;
  final now = DateTime(2026, 11, 12);

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockAnalyticsRepository();
  });

  test('MonthAnalytics.fromJson reads the server format', () {
    expect(november.expense, 40000.0);
    expect(november.forecastExpense, 90000.0);
    expect(november.byCategory[1].categoryId, isNull);
    expect(november.daily[1].date, DateTime(2026, 11, 2));
    expect(november.impulse.count, 2);
  });

  test('null forecast and change are allowed (past month)', () {
    final json = serverJson('2026-10')
      ..['forecast_expense'] = null
      ..['expense_change_percent'] = null;
    final data = MonthAnalytics.fromJson(json);
    expect(data.forecastExpense, isNull);
    expect(data.expenseChangePercent, isNull);
  });

  test('starts at the first day of the current month', () {
    final bloc = AnalyticsBloc(repository, now: now);
    expect(bloc.state.month, DateTime(2026, 11));
    expect(bloc.state.isCurrentMonth(now), isTrue);
  });

  blocTest<AnalyticsBloc, AnalyticsState>(
    'AnalyticsRequested loads the current month',
    build: () {
      when(() => repository.fetchMonth(any()))
          .thenAnswer((_) async => november);
      return AnalyticsBloc(repository, now: now);
    },
    act: (bloc) => bloc.add(const AnalyticsRequested()),
    expect: () => [
      AnalyticsState(month: DateTime(2026, 11), status: AnalyticsStatus.loading),
      AnalyticsState(
        month: DateTime(2026, 11),
        status: AnalyticsStatus.success,
        data: november,
      ),
    ],
    verify: (_) =>
        verify(() => repository.fetchMonth(DateTime(2026, 11))).called(1),
  );

  blocTest<AnalyticsBloc, AnalyticsState>(
    'AnalyticsMonthShifted(-1) goes to the previous month and loads it',
    build: () {
      when(() => repository.fetchMonth(DateTime(2026, 10)))
          .thenAnswer((_) async => october);
      return AnalyticsBloc(repository, now: now);
    },
    seed: () => AnalyticsState(
      month: DateTime(2026, 11),
      status: AnalyticsStatus.success,
      data: november,
    ),
    act: (bloc) => bloc.add(const AnalyticsMonthShifted(-1)),
    expect: () => [
      // Old data stays until the new month arrives, the screen hides it
      AnalyticsState(
        month: DateTime(2026, 10),
        status: AnalyticsStatus.success,
        data: november,
      ),
      AnalyticsState(
        month: DateTime(2026, 10),
        status: AnalyticsStatus.loading,
        data: november,
      ),
      AnalyticsState(
        month: DateTime(2026, 10),
        status: AnalyticsStatus.success,
        data: october,
      ),
    ],
  );

  blocTest<AnalyticsBloc, AnalyticsState>(
    'going back from January gives December of the previous year',
    build: () {
      when(() => repository.fetchMonth(any()))
          .thenAnswer((_) async => october);
      return AnalyticsBloc(repository, now: DateTime(2027, 1, 5));
    },
    act: (bloc) => bloc.add(const AnalyticsMonthShifted(-1)),
    verify: (bloc) => expect(bloc.state.month, DateTime(2026, 12)),
  );

  blocTest<AnalyticsBloc, AnalyticsState>(
    'shows the server error',
    build: () {
      when(() => repository.fetchMonth(any()))
          .thenThrow(const ApiException('No connection to the server'));
      return AnalyticsBloc(repository, now: now);
    },
    act: (bloc) => bloc.add(const AnalyticsRequested()),
    expect: () => [
      AnalyticsState(month: DateTime(2026, 11), status: AnalyticsStatus.loading),
      AnalyticsState(
        month: DateTime(2026, 11),
        status: AnalyticsStatus.failure,
        errorMessage: 'No connection to the server',
      ),
    ],
  );
}