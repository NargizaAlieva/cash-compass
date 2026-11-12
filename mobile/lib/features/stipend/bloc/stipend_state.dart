import 'package:cash_compass/features/stipend/data/stipend_allowance.dart';
import 'package:equatable/equatable.dart';

enum StipendStatus { initial, loading, success, failure }

class StipendState extends Equatable {
  const StipendState({
    this.status = StipendStatus.initial,
    this.allowance,
    this.errorMessage,
  });

  final StipendStatus status;

  /// null until the first successful load.
  final StipendAllowance? allowance;
  final String? errorMessage;

  /// Note: errorMessage is NOT copied, so every new state clears the old error.
  StipendState copyWith({
    StipendStatus? status,
    StipendAllowance? allowance,
    String? errorMessage,
  }) {
    return StipendState(
      status: status ?? this.status,
      allowance: allowance ?? this.allowance,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allowance, errorMessage];
}