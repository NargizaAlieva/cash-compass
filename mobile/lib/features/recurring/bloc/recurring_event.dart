import 'package:cash_compass/features/recurring/data/recurring_payment.dart';
import 'package:equatable/equatable.dart';

sealed class RecurringEvent extends Equatable {
  const RecurringEvent();

  @override
  List<Object?> get props => [];
}

final class RecurringRequested extends RecurringEvent {
  const RecurringRequested();
}

final class RecurringAdded extends RecurringEvent {
  const RecurringAdded(this.draft);

  final RecurringDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class RecurringUpdated extends RecurringEvent {
  const RecurringUpdated(this.id, this.draft);

  final int id;
  final RecurringDraft draft;

  @override
  List<Object?> get props => [id, draft];
}

/// The switch on a payment: pause or resume it.
final class RecurringToggled extends RecurringEvent {
  const RecurringToggled(this.id, {required this.isActive});

  final int id;
  final bool isActive;

  @override
  List<Object?> get props => [id, isActive];
}

final class RecurringDeleted extends RecurringEvent {
  const RecurringDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
