import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum TransactionKind { expense, income, transfer }

final _dateFormat = DateFormat('yyyy-MM-dd');

/// A transaction that is already saved on the server.
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.kind,
    required this.amount,
    required this.accountId,
    required this.date,
    this.toAccountId,
    this.categoryId,
    this.note = '',
    this.isImpulsive = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        kind: TransactionKind.values.byName(json['kind'] as String),
        amount: (json['amount'] as num).toDouble(),
        accountId: json['account_id'] as int,
        toAccountId: json['to_account_id'] as int?,
        categoryId: json['category_id'] as int?,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String,
        isImpulsive: json['is_impulsive'] as bool,
      );

  final int id;
  final TransactionKind kind;

  /// Always positive. [kind] says if money came in or went out.
  final double amount;
  final int accountId;

  /// Only for transfers.
  final int? toAccountId;

  /// Not used for transfers.
  final int? categoryId;
  final DateTime date;
  final String note;
  final bool isImpulsive;

  @override
  List<Object?> get props => [
        id,
        kind,
        amount,
        accountId,
        toAccountId,
        categoryId,
        date,
        note,
        isImpulsive,
      ];
}

/// What the user filled in the form. Sent to the server to create or update.
class TransactionDraft extends Equatable {
  const TransactionDraft({
    required this.kind,
    required this.amount,
    required this.accountId,
    required this.date,
    this.toAccountId,
    this.categoryId,
    this.note = '',
    this.isImpulsive = false,
  });

  final TransactionKind kind;
  final double amount;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final DateTime date;
  final String note;
  final bool isImpulsive;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'amount': amount,
        'account_id': accountId,
        'to_account_id': toAccountId,
        'category_id': categoryId,
        'date': _dateFormat.format(date),
        'note': note,
        'is_impulsive': isImpulsive,
      };

  @override
  List<Object?> get props => [
        kind,
        amount,
        accountId,
        toAccountId,
        categoryId,
        date,
        note,
        isImpulsive,
      ];
}