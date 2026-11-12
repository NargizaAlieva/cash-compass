import 'package:cash_compass/features/accounts/data/account.dart';
import 'package:equatable/equatable.dart';

enum AccountsStatus { initial, loading, success, failure }

class AccountsState extends Equatable {
  const AccountsState({
    this.status = AccountsStatus.initial,
    this.accounts = const [],
    this.totalBalance = 0,
    this.errorMessage,
  });

  final AccountsStatus status;
  final List<Account> accounts;
  final double totalBalance;

  /// Error to show once (as a SnackBar).
  final String? errorMessage;

  /// Note: errorMessage is NOT copied, so every new state clears the old error.
  AccountsState copyWith({
    AccountsStatus? status,
    List<Account>? accounts,
    double? totalBalance,
    String? errorMessage,
  }) {
    return AccountsState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      totalBalance: totalBalance ?? this.totalBalance,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, accounts, totalBalance, errorMessage];
}