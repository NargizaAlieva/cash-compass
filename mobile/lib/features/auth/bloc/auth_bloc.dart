import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/auth/bloc/auth_event.dart';
import 'package:cash_compass/features/auth/bloc/auth_state.dart';
import 'package:cash_compass/features/auth/data/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _repository.restoreSession();
      emit(
        user == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(user),
      );
    } on ApiException catch (error) {
      emit(AuthState.unauthenticated(errorMessage: error.message));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.unauthenticated(isSubmitting: true));
    try {
      final user = await _repository.login(event.email, event.password);
      emit(AuthState.authenticated(user));
    } on ApiException catch (error) {
      emit(AuthState.unauthenticated(errorMessage: error.message));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.unauthenticated(isSubmitting: true));
    try {
      final user = await _repository.register(
        event.name,
        event.email,
        event.password,
      );
      emit(AuthState.authenticated(user));
    } on ApiException catch (error) {
      emit(AuthState.unauthenticated(errorMessage: error.message));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthState.unauthenticated());
  }
}