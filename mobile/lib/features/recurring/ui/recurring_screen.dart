import 'package:cash_compass/core/ui/category_style.dart';
import 'package:cash_compass/core/ui/error_view.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/categories/bloc/categories_bloc.dart';
import 'package:cash_compass/features/recurring/bloc/recurring_bloc.dart';
import 'package:cash_compass/features/recurring/data/recurring_payment.dart';
import 'package:cash_compass/features/recurring/ui/recurring_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Opens the list of regular payments. The screen is opened on top of
/// MainShell, so we pass the Blocs it needs.
void openRecurringScreen(BuildContext context) {
  final recurringBloc = context.read<RecurringBloc>();
  final accountsBloc = context.read<AccountsBloc>();
  final categoriesBloc = context.read<CategoriesBloc>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: recurringBloc),
          BlocProvider.value(value: accountsBloc),
          BlocProvider.value(value: categoriesBloc),
        ],
        child: const RecurringScreen(),
      ),
    ),
  );
}

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  /// Opens the form and sends the result to RecurringBloc.
  Future<void> _openForm(BuildContext context, {RecurringPayment? payment}) async {
    final bloc = context.read<RecurringBloc>();
    final accounts = context.read<AccountsBloc>().state.accounts;
    final categories = context.read<CategoriesBloc>().state.categories;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an account first')),
      );
      return;
    }

    final result = await Navigator.of(context).push<RecurringFormResult>(
      MaterialPageRoute(
        builder: (_) => RecurringFormScreen(
          accounts: accounts,
          categories: categories,
          payment: payment,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.delete) {
      bloc.add(RecurringDeleted(payment!.id));
    } else if (payment == null) {
      bloc.add(RecurringAdded(result.draft!));
    } else {
      bloc.add(RecurringUpdated(payment.id, result.draft!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regular payments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocConsumer<RecurringBloc, RecurringState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.status == RecurringStatus.initial ||
              (state.status == RecurringStatus.loading && state.payments.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == RecurringStatus.failure && state.payments.isEmpty) {
            return ErrorView(
              message: state.errorMessage ?? 'Could not load payments',
              onRetry: () =>
                  context.read<RecurringBloc>().add(const RecurringRequested()),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _TotalsCard(monthly: state.monthlyTotal, yearly: state.yearlyTotal),
              const SizedBox(height: 8),
              if (state.payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No regular payments yet.\n'
                    'Add rent, subscriptions or your phone bill, '
                    'and they will be added every month by themselves.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final payment in state.payments)
                _PaymentTile(
                  payment: payment,
                  onTap: () => _openForm(context, payment: payment),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// "16 990 som a month · 203 880 som a year".
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.monthly, required this.yearly});

  final double monthly;
  final double yearly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Every month', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              formatMoney(monthly),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text('That is ${formatMoney(yearly)} a year'),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.onTap});

  final RecurringPayment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categories =
        context.select((CategoriesBloc bloc) => bloc.state.categories);
    final accounts = context.select((AccountsBloc bloc) => bloc.state.accounts);
    final category =
        categories.where((c) => c.id == payment.categoryId).firstOrNull;
    final account =
        accounts.where((a) => a.id == payment.accountId).firstOrNull;
    final color = category == null ? Colors.grey : colorFromHex(category.color);

    final details = payment.isActive
        ? 'Day ${payment.dayOfMonth} · ${account?.name ?? '?'} · '
            'next ${DateFormat('d MMM').format(payment.nextDate)}'
        : 'Paused';

    return Opacity(
      // Paused payments look faded
      opacity: payment.isActive ? 1 : 0.5,
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(iconFromName(category?.icon ?? 'category'), color: color),
          ),
          title: Text(payment.name),
          subtitle: Text(details),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatMoney(payment.amount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Switch(
                value: payment.isActive,
                onChanged: (value) => context
                    .read<RecurringBloc>()
                    .add(RecurringToggled(payment.id, isActive: value)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
