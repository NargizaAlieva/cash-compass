import 'package:cash_compass/features/budgets/bloc/budgets_bloc.dart';
import 'package:cash_compass/features/budgets/data/budget.dart';
import 'package:cash_compass/features/budgets/ui/budget_progress.dart';
import 'package:cash_compass/features/categories/bloc/categories_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Warning on Home when some limits are almost used up or exceeded.
/// Shows nothing when all limits are fine.
class BudgetAlertsCard extends StatelessWidget {
  const BudgetAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = context.select((BudgetsBloc bloc) => bloc.state.alerts);
    final categories =
        context.select((CategoriesBloc bloc) => bloc.state.categories);

    // Pair each alert with its category name (skip deleted categories)
    final rows = <(String, BudgetStatus)>[];
    for (final alert in alerts) {
      final category =
          categories.where((c) => c.id == alert.categoryId).firstOrNull;
      if (category != null) {
        rows.add((category.name, alert));
      }
    }
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final anyOver = rows.any((row) => row.$2.level == BudgetLevel.over);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  anyOver ? Icons.error_outline : Icons.warning_amber_rounded,
                  color: budgetLevelColor(
                    context,
                    anyOver ? BudgetLevel.over : BudgetLevel.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  anyOver ? 'Limit exceeded' : 'Limit almost used',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            for (final (name, budget) in rows) ...[
              const SizedBox(height: 12),
              Text(name, style: theme.textTheme.bodyMedium),
              BudgetProgress(budget: budget),
            ],
          ],
        ),
      ),
    );
  }
}