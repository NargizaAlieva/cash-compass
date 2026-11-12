import 'package:cash_compass/core/ui/formatters.dart';
import 'package:flutter/material.dart';

/// Big card with the sum of all accounts.
class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key, required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onPrimaryContainer;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total balance',
              style: theme.textTheme.titleSmall?.copyWith(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              formatMoney(total),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}