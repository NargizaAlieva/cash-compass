import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:cash_compass/features/auth/data/auth_repository.dart';
import 'package:cash_compass/features/auth/data/user.dart';
import 'package:cash_compass/features/stipend/bloc/stipend_bloc.dart';
import 'package:cash_compass/features/stipend/data/stipend_allowance.dart';
import 'package:cash_compass/features/stipend/data/stipend_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStipendRepository extends Mock implements StipendRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

final allowance = StipendAllowance.fromJson({
  'configured': true,
  'stipend_day': 25,
  'next_stipend_date': '2026-11-25',
  'days_left': 13,
  'balance': 45000,
  'daily_allowance': 3461.54,
  'spent_today': 1000,
  'left_today': 2461.54,
});

void main() {
  group('StipendAllowance.fromJson', () {
    test('reads a configured allowance', () {
      expect(allowance.configured, isTrue);
      expect(allowance.nextStipendDate, DateTime(2026, 11, 25));
      expect(allowance.daysLeft, 13);
      expect(allowance.leftToday, 2461.54);
    });

    test('reads a not configured allowance with nulls', () {
      final empty = StipendAllowance.fromJson({
        'configured': false,
        'stipend_day': null,
        'next_stipend_date': null,
        'days_left': null,
        'balance': null,
        'daily_allowance': null,
        'spent_today': null,
        'left_today': null,
      });
      expect(empty.configured, isFalse);
      expect(empty.nextStipendDate, isNull);
    });
  });

  group('StipendBloc', () {
    late MockStipendRepository repository;

    setUp(() {
      repository = MockStipendRepository();
    });

    blocTest<StipendBloc, StipendState>(
      'StipendRequested loads the allowance',
      build: () {
        when(() => repository.fetchAllowance())
            .thenAnswer((_) async => allowance);
        return StipendBloc(repository);
      },
      act: (bloc) => bloc.add(const StipendRequested()),
      expect: () => [
        const StipendState(status: StipendStatus.loading),
        StipendState(status: StipendStatus.success, allowance: allowance),
      ],
    );

    blocTest<StipendBloc, StipendState>(
      'keeps the old allowance on the screen when reload fails',
      build: () {
        when(() => repository.fetchAllowance())
            .thenThrow(const ApiException('No connection to the server'));
        return StipendBloc(repository);
      },
      seed: () =>
          StipendState(status: StipendStatus.success, allowance: allowance),
      act: (bloc) => bloc.add(const StipendRequested()),
      expect: () => [
        StipendState(status: StipendStatus.loading, allowance: allowance),
        StipendState(
          status: StipendStatus.failure,
          allowance: allowance,
          errorMessage: 'No connection to the server',
        ),
      ],
    );
  });

  group('AuthBloc stipend settings', () {
    late MockAuthRepository repository;
    const user = User(id: 1, email: 'test@example.com', name: 'Test');
    const updated = User(
      id: 1,
      email: 'test@example.com',
      name: 'Test',
      stipendDay: 25,
      stipendAmount: 45000,
    );

    setUp(() {
      repository = MockAuthRepository();
    });

    blocTest<AuthBloc, AuthState>(
      'saves the stipend day and updates the user',
      build: () {
        when(
          () => repository.updateStipendSettings(
            stipendDay: 25,
            stipendAmount: 45000,
          ),
        ).thenAnswer((_) async => updated);
        return AuthBloc(repository);
      },
      seed: () => const AuthState.authenticated(user),
      act: (bloc) => bloc.add(
        const AuthStipendSettingsChanged(stipendDay: 25, stipendAmount: 45000),
      ),
      expect: () => [const AuthState.authenticated(updated)],
    );

    blocTest<AuthBloc, AuthState>(
      'stays logged in and shows the error if saving fails',
      build: () {
        when(
          () => repository.updateStipendSettings(
            stipendDay: any(named: 'stipendDay'),
            stipendAmount: any(named: 'stipendAmount'),
          ),
        ).thenThrow(const ApiException('Please check the entered data'));
        return AuthBloc(repository);
      },
      seed: () => const AuthState.authenticated(user),
      act: (bloc) =>
          bloc.add(const AuthStipendSettingsChanged(stipendDay: 25)),
      expect: () => [
        const AuthState.authenticated(
          user,
          errorMessage: 'Please check the entered data',
        ),
      ],
    );
  });
}