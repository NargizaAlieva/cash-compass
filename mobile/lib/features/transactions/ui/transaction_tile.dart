import 'package:cash_compass/core/ui/category_style.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/categories/bloc/categories_bloc.dart';
import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _incomeColor = Color(0xFF2E7D32);

/// One row: category icon, name, account, note and the amount.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The transaction only has ids, so we look up names in the other Blocs
    final accounts = context.select((AccountsBloc bloc) => bloc.state.accounts);
    final categories =
        context.select((CategoriesBloc bloc) => bloc.state.categories);

    String accountName(int? id) =>
        accounts.where((a) => a.id == id).firstOrNull?.name ?? '?';
    final category =
        categories.where((c) => c.id == transaction.categoryId).firstOrNull;

    final IconData icon;
    final Color iconColor;
    final String title;
    final String details;
    final String amountText;
    final Color? amountColor;

    switch (transaction.kind) {
      case TransactionKind.transfer:
        icon = Icons.swap_horiz;
        iconColor = theme.colorScheme.primary;
        title = 'Transfer';
        details =
            '${accountName(transaction.accountId)} → ${accountName(transaction.toAccountId)}';
        amountText = formatMoney(transaction.amount);
        amountColor = null;
      case TransactionKind.expense:
      case TransactionKind.income:
        final isIncome = transaction.kind == TransactionKind.income;
        icon = iconFromName(category?.icon ?? 'category');
        iconColor = category == null
            ? theme.colorScheme.outline
            : colorFromHex(category.color);
        title = category?.name ?? 'No category';
        details = accountName(transaction.accountId);
        amountText = '${isIncome ? '+' : '−'}${formatMoney(transaction.amount)}';
        amountColor = isIncome ? _incomeColor : theme.colorScheme.error;
    }

    final subtitle = transaction.note.isEmpty
        ? details
        : '$details · ${transaction.note}';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.15),
        child: Icon(icon, color: iconColor),
      ),
      title: Row(
        children: [
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          if (transaction.recurringPaymentId != null)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Tooltip(
                message: 'Regular payment',
                child: Icon(Icons.repeat, size: 16),
              ),
            ),
          if (transaction.isImpulsive)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Tooltip(
                message: 'Impulse purchase',
                child: Icon(Icons.bolt, size: 16, color: Colors.amber),
              ),
            ),
        ],
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        amountText,
        style: theme.textTheme.titleMedium?.copyWith(color: amountColor),
      ),
    );
  }
}