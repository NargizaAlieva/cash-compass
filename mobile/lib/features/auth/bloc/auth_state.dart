import 'package:cash_compass/features/auth/data/user.dart';
import 'package:equatable/equatable.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// App just started, session is not checked yet.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({
    bool isSubmitting = false,
    String? errorMessage,
  }) : this._(
          status: AuthStatus.unauthenticated,
          isSubmitting: isSubmitting,
          errorMessage: errorMessage,
        );

  final AuthStatus status;
  final User? user;

  /// Login or register request is in progress.
  final bool isSubmitting;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, user, isSubmitting, errorMessage];
}