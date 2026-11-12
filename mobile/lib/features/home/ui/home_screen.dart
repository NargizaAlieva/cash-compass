import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/accounts/ui/total_balance_card.dart';
import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:cash_compass/features/transactions/bloc/transactions_bloc.dart';
import 'package:cash_compass/features/transactions/ui/open_transaction_form.dart';
import 'package:cash_compass/features/transactions/ui/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cash_compass/features/budgets/ui/budget_alerts_card.dart';
import 'package:cash_compass/features/accounts/ui/accounts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  
  /// Accounts open as a separate screen. The new screen is outside
  /// MainShell, so we pass the existing AccountsBloc to it.
  void _openAccounts(BuildContext context) {
    final accountsBloc = context.read<AccountsBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: accountsBloc,
          child: const AccountsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select((AuthBloc bloc) => bloc.state.user?.name);
    final total = context.select((AccountsBloc bloc) => bloc.state.totalBalance);
    final recent = context.select(
      (TransactionsBloc bloc) => bloc.state.transactions.take(5).toList(),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CashCompass')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
        onPressed: () => openTransactionForm(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text('Hello, ${name ?? ''}!', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
                    TotalBalanceCard(total: total, onTap: () => _openAccounts(context)),
          const SizedBox(height: 8),
          // Shows nothing when all limits are fine
          const BudgetAlertsCard(),
          const SizedBox(height: 16),
          Text('Recent transactions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No transactions yet. Tap + to add your first one.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final transaction in recent)
            TransactionTile(
              transaction: transaction,
              onTap: () =>
                  openTransactionForm(context, transaction: transaction),
            ),
        ],
      ),
    );
  }
}