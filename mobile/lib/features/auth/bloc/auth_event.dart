import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App started: check if there is a saved session.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}


/// The user saved stipend settings in Profile (or on Home).
final class AuthStipendSettingsChanged extends AuthEvent {
  const AuthStipendSettingsChanged({
    required this.stipendDay,
    this.stipendAmount,
  });

  final int stipendDay;
  final double? stipendAmount;

  @override
  List<Object?> get props => [stipendDay, stipendAmount];
}