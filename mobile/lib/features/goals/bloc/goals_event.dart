import 'package:cash_compass/features/goals/data/goal.dart';
import 'package:equatable/equatable.dart';

sealed class GoalsEvent extends Equatable {
  const GoalsEvent();

  @override
  List<Object?> get props => [];
}

final class GoalsRequested extends GoalsEvent {
  const GoalsRequested();
}

final class GoalAdded extends GoalsEvent {
  const GoalAdded(this.draft);

  final GoalDraft draft;

  @override
  List<Object?> get props => [draft];
}

/// Also used for "I saved more": the new saved amount comes in the draft.
final class GoalUpdated extends GoalsEvent {
  const GoalUpdated(this.id, this.draft);

  final int id;
  final GoalDraft draft;

  @override
  List<Object?> get props => [id, draft];
}

final class GoalDeleted extends GoalsEvent {
  const GoalDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
