import 'package:cash_compass/features/goals/data/goal.dart';
import 'package:equatable/equatable.dart';

enum GoalsStatus { initial, loading, success, failure }

class GoalsState extends Equatable {
  const GoalsState({
    this.status = GoalsStatus.initial,
    this.goals = const [],
    this.monthlySaving = 0,
    this.errorMessage,
  });

  final GoalsStatus status;
  final List<Goal> goals;
  final double monthlySaving;

  /// Error to show once (as a SnackBar).
  final String? errorMessage;

  /// Note: errorMessage is NOT copied, so every new state clears the old error.
  GoalsState copyWith({
    GoalsStatus? status,
    List<Goal>? goals,
    double? monthlySaving,
    String? errorMessage,
  }) {
    return GoalsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      monthlySaving: monthlySaving ?? this.monthlySaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, goals, monthlySaving, errorMessage];
}
