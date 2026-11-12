import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:flutter/material.dart';

/// How much of the spending was "wanted it" instead of "needed it".
class ImpulseBlock extends StatelessWidget {
  const ImpulseBlock({super.key, required this.impulse});

  final ImpulseStats impulse;

  @override
  Widget build(BuildContext context) {
    if (impulse.count == 0) {
      return const Text('No impulse purchases this month. Well done!');
    }
    final theme = Theme.of(context);
    const color = Colors.amber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: color),
            const SizedBox(width: 8),
            Text(
              '${impulse.percent.round()}% of spending',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (impulse.percent / 100).clamp(0, 1),
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${formatMoney(impulse.amount)} on ${impulse.count} '
          '${impulse.count == 1 ? 'purchase' : 'purchases'} you wanted, '
          'but did not really need',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}