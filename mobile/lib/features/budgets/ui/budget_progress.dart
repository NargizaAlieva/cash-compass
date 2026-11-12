import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/budgets/data/budget.dart';
import 'package:flutter/material.dart';

/// Green below 80%, amber from 80%, red from 100%.
Color budgetLevelColor(BuildContext context, BudgetLevel level) =>
    switch (level) {
      BudgetLevel.ok => const Color(0xFF2E7D32),
      BudgetLevel.warning => const Color(0xFFF9A825),
      BudgetLevel.over => Theme.of(context).colorScheme.error,
    };

/// Progress bar + "12 000 of 40 000 som · 30%".
class BudgetProgress extends StatelessWidget {
  const BudgetProgress({super.key, required this.budget});

  final BudgetStatus budget;

  @override
  Widget build(BuildContext context) {
    final color = budgetLevelColor(context, budget.level);
    final text = budget.level == BudgetLevel.over
        ? 'Over by ${formatMoney(-budget.remaining)} · ${budget.percent.round()}%'
        : '${formatMoney(budget.spent)} of ${formatMoney(budget.limitAmount)}'
            ' · ${budget.percent.round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            // The bar stops at 100%, the text shows how much more was spent
            value: (budget.percent / 100).clamp(0, 1),
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: budget.level == BudgetLevel.ok ? null : color,
              ),
        ),
      ],
    );
  }
}