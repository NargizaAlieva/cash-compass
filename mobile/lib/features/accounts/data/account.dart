import 'package:equatable/equatable.dart';

enum AccountType { cash, card }

class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as int,
        name: json['name'] as String,
        type: AccountType.values.byName(json['type'] as String),
        currency: json['currency'] as String,
        balance: (json['balance'] as num).toDouble(),
      );

  final int id;
  final String name;
  final AccountType type;
  final String currency;
  final double balance;

  @override
  List<Object?> get props => [id, name, type, currency, balance];
}

/// Response of GET /accounts: all accounts + their total.
class AccountsSummary extends Equatable {
  const AccountsSummary({required this.accounts, required this.totalBalance});

  factory AccountsSummary.fromJson(Map<String, dynamic> json) =>
      AccountsSummary(
        accounts: (json['accounts'] as List<dynamic>)
            .map((item) => Account.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalBalance: (json['total_balance'] as num).toDouble(),
      );

  final List<Account> accounts;
  final double totalBalance;

  @override
  List<Object?> get props => [accounts, totalBalance];
}