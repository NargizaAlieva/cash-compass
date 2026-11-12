import 'package:cash_compass/features/accounts/data/account.dart';
import 'package:equatable/equatable.dart';

sealed class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) accounts from the server.
final class AccountsRequested extends AccountsEvent {
  const AccountsRequested();
}

final class AccountAdded extends AccountsEvent {
  const AccountAdded({
    required this.name,
    required this.type,
    required this.balance,
  });

  final String name;
  final AccountType type;
  final double balance;

  @override
  List<Object?> get props => [name, type, balance];
}

final class AccountUpdated extends AccountsEvent {
  const AccountUpdated({
    required this.id,
    required this.name,
    required this.type,
  });

  final int id;
  final String name;
  final AccountType type;

  @override
  List<Object?> get props => [id, name, type];
}

final class AccountDeleted extends AccountsEvent {
  const AccountDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}