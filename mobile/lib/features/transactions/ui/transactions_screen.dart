import 'package:cash_compass/core/ui/error_view.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/transactions/bloc/transactions_bloc.dart';
import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:cash_compass/features/transactions/ui/open_transaction_form.dart';
import 'package:cash_compass/features/transactions/ui/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTransactionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocConsumer<TransactionsBloc, TransactionsState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          final nothingLoadedYet = state.transactions.isEmpty;

          if (state.status == TransactionsStatus.initial ||
              (state.status == TransactionsStatus.loading &&
                  nothingLoadedYet)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TransactionsStatus.failure && nothingLoadedYet) {
            return ErrorView(
              message: state.errorMessage ?? 'Could not load transactions',
              onRetry: () => context.read<TransactionsBloc>().add(
                const TransactionsRequested(),
              ),
            );
          }

          final visible = state.visibleTransactions;
          return Column(
            children: [
              _KindFilter(selected: state.kindFilter),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions yet.\nTap "Add" to record one.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _GroupedByDay(transactions: visible),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chips: All / Expenses / Income / Transfers.
class _KindFilter extends StatelessWidget {
  const _KindFilter({required this.selected});

  final TransactionKind? selected;

  static const _options = <(String, TransactionKind?)>[
    ('All', null),
    ('Expenses', TransactionKind.expense),
    ('Income', TransactionKind.income),
    ('Transfers', TransactionKind.transfer),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final (label, kind) in _options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == kind,
                onSelected: (_) => context.read<TransactionsBloc>().add(
                  TransactionsFilterChanged(kind),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// List with a header for every day: "Today", "Yesterday", "10 Nov".
class _GroupedByDay extends StatelessWidget {
  const _GroupedByDay({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelLarge;
    final children = <Widget>[];
    DateTime? currentDay;

    // Transactions come newest first, so the same days are next to each other
    for (final transaction in transactions) {
      if (transaction.date != currentDay) {
        currentDay = transaction.date;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(formatDay(transaction.date), style: headerStyle),
          ),
        );
      }
      children.add(
        TransactionTile(
          transaction: transaction,
          onTap: () => openTransactionForm(context, transaction: transaction),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: children,
    );
  }
}