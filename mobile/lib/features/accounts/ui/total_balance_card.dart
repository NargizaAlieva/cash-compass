import 'package:cash_compass/core/ui/formatters.dart';
import 'package:flutter/material.dart';

/// Big card with the sum of all accounts.
/// If [onTap] is set, the card shows an arrow and can be tapped.
class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key, required this.total, this.onTap});

  final double total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onPrimaryContainer;

    return Card(
      color: theme.colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias, // so the tap ripple has round corners
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total balance',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: textColor,
                      ),
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
              if (onTap != null) Icon(Icons.chevron_right, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}