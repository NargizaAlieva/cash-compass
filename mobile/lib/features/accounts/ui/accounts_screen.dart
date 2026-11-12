import 'package:cash_compass/core/ui/confirm_dialog.dart';
import 'package:cash_compass/core/ui/error_view.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/accounts/data/account.dart';
import 'package:cash_compass/features/accounts/ui/account_form_dialog.dart';
import 'package:cash_compass/features/accounts/ui/total_balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _addAccount(BuildContext context) async {
    final bloc = context.read<AccountsBloc>();
    final result = await showAccountFormDialog(context);
    if (result != null) {
      bloc.add(
        AccountAdded(
          name: result.name,
          type: result.type,
          balance: result.balance,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAccount(context),
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
      body: BlocConsumer<AccountsBloc, AccountsState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          final nothingLoadedYet = state.accounts.isEmpty;

          if (state.status == AccountsStatus.initial ||
              (state.status == AccountsStatus.loading && nothingLoadedYet)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AccountsStatus.failure && nothingLoadedYet) {
            return ErrorView(
              message: state.errorMessage ?? 'Could not load accounts',
              onRetry: () =>
                  context.read<AccountsBloc>().add(const AccountsRequested()),
            );
          }

          return ListView(
            // Bottom padding so the button does not cover the last account
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              TotalBalanceCard(total: state.totalBalance),
              const SizedBox(height: 16),
              if (state.accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No accounts yet.\nAdd your cash and bank cards.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final account in state.accounts)
                _AccountTile(account: account),
            ],
          );
        },
      ),
    );
  }
}

enum _AccountAction { edit, delete }

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});

  final Account account;

  Future<void> _onAction(BuildContext context, _AccountAction action) async {
    final bloc = context.read<AccountsBloc>();

    switch (action) {
      case _AccountAction.edit:
        final result = await showAccountFormDialog(context, account: account);
        if (result != null) {
          bloc.add(
            AccountUpdated(id: account.id, name: result.name, type: result.type),
          );
        }
      case _AccountAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete account?',
          message: '"${account.name}" will be deleted.',
        );
        if (confirmed) {
          bloc.add(AccountDeleted(account.id));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCash = account.type == AccountType.cash;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isCash ? Icons.payments_outlined : Icons.credit_card),
        ),
        title: Text(account.name),
        subtitle: Text(isCash ? 'Cash' : 'Card'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatMoney(account.balance),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            PopupMenuButton<_AccountAction>(
              onSelected: (action) => _onAction(context, action),
              itemBuilder: (_) => const [
                PopupMenuItem(value: _AccountAction.edit, child: Text('Edit')),
                PopupMenuItem(
                  value: _AccountAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}