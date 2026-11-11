import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:cash_compass/features/auth/data/auth_repository.dart';
import 'package:cash_compass/features/auth/data/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const user = User(id: 1, email: 'test@example.com', name: 'Test');

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  test('initial state is unknown', () {
    expect(AuthBloc(repository).state, const AuthState.unknown());
  });

  group('AuthStarted', () {
    blocTest<AuthBloc, AuthState>(
      'emits authenticated when a session is saved',
      build: () {
        when(() => repository.restoreSession()).thenAnswer((_) async => user);
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState.authenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when there is no session',
      build: () {
        when(() => repository.restoreSession()).thenAnswer((_) async => null);
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState.unauthenticated()],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits submitting, then authenticated on success',
      build: () {
        when(() => repository.login(any(), any()))
            .thenAnswer((_) async => user);
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'test@example.com', password: '123456'),
      ),
      expect: () => [
        const AuthState.unauthenticated(isSubmitting: true),
        const AuthState.authenticated(user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits submitting, then error on wrong password',
      build: () {
        when(() => repository.login(any(), any())).thenThrow(
          const ApiException('Invalid email or password', statusCode: 401),
        );
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'test@example.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthState.unauthenticated(isSubmitting: true),
        const AuthState.unauthenticated(
          errorMessage: 'Invalid email or password',
        ),
      ],
    );
  });

  group('AuthRegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits submitting, then authenticated on success',
      build: () {
        when(() => repository.register(any(), any(), any()))
            .thenAnswer((_) async => user);
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          name: 'Test',
          email: 'test@example.com',
          password: '123456',
        ),
      ),
      expect: () => [
        const AuthState.unauthenticated(isSubmitting: true),
        const AuthState.authenticated(user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits error when email is taken',
      build: () {
        when(() => repository.register(any(), any(), any())).thenThrow(
          const ApiException('Email is already registered', statusCode: 409),
        );
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          name: 'Test',
          email: 'test@example.com',
          password: '123456',
        ),
      ),
      expect: () => [
        const AuthState.unauthenticated(isSubmitting: true),
        const AuthState.unauthenticated(
          errorMessage: 'Email is already registered',
        ),
      ],
    );
  });

  blocTest<AuthBloc, AuthState>(
    'AuthLogoutRequested clears the session',
    build: () {
      when(() => repository.logout()).thenAnswer((_) async {});
      return AuthBloc(repository);
    },
    seed: () => const AuthState.authenticated(user),
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => [const AuthState.unauthenticated()],
    verify: (_) => verify(() => repository.logout()).called(1),
  );
}