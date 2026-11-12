import 'package:equatable/equatable.dart';

sealed class StipendEvent extends Equatable {
  const StipendEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) today's allowance from the server.
final class StipendRequested extends StipendEvent {
  const StipendRequested();
}