import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/categories/bloc/categories_bloc.dart';
import 'package:cash_compass/features/transactions/bloc/transactions_bloc.dart';
import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:cash_compass/features/transactions/ui/transaction_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the transaction form and sends the result to [TransactionsBloc].
/// Pass [transaction] to edit it, or nothing to add a new one.
///
/// Used from the Transactions tab and from Home.
Future<void> openTransactionForm(
  BuildContext context, {
  Transaction? transaction,
}) async {
  final transactionsBloc = context.read<TransactionsBloc>();
  final accounts = context.read<AccountsBloc>().state.accounts;
  final categories = context.read<CategoriesBloc>().state.categories;

  if (accounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add an account first: tap the balance card on Home')),    );
    return;
  }

  final result = await Navigator.of(context).push<TransactionFormResult>(
    MaterialPageRoute(
      builder: (_) => TransactionFormScreen(
        accounts: accounts,
        categories: categories,
        transaction: transaction,
      ),
    ),
  );
  if (result == null) {
    return; // the user pressed Back
  }

  if (result.delete) {
    transactionsBloc.add(TransactionDeleted(transaction!.id));
  } else if (transaction == null) {
    transactionsBloc.add(TransactionAdded(result.draft!));
  } else {
    transactionsBloc.add(TransactionUpdated(transaction.id, result.draft!));
  }
}