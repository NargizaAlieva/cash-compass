import 'package:cash_compass/features/recurring/data/recurring_payment.dart';
import 'package:equatable/equatable.dart';

enum RecurringStatus { initial, loading, success, failure }

class RecurringState extends Equatable {
  const RecurringState({
    this.status = RecurringStatus.initial,
    this.payments = const [],
    this.monthlyTotal = 0,
    this.yearlyTotal = 0,
    this.changeCount = 0,
    this.errorMessage,
  });

  final RecurringStatus status;
  final List<RecurringPayment> payments;
  final double monthlyTotal;
  final double yearlyTotal;

  /// Grows after every successful change. A payment due today is charged
  /// right away, so other Blocs reload when this number changes.
  final int changeCount;

  /// Error to show once (as a SnackBar).
  final String? errorMessage;

  /// Note: errorMessage is NOT copied, so every new state clears the old error.
  RecurringState copyWith({
    RecurringStatus? status,
    List<RecurringPayment>? payments,
    double? monthlyTotal,
    double? yearlyTotal,
    int? changeCount,
    String? errorMessage,
  }) {
    return RecurringState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      monthlyTotal: monthlyTotal ?? this.monthlyTotal,
      yearlyTotal: yearlyTotal ?? this.yearlyTotal,
      changeCount: changeCount ?? this.changeCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, payments, monthlyTotal, yearlyTotal, changeCount, errorMessage];
}
