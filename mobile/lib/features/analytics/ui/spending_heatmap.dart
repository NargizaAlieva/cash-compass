import 'dart:math' as math;

import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:flutter/material.dart';

/// Calendar of the month. The darker the day, the more was spent.
class SpendingHeatmap extends StatelessWidget {
  const SpendingHeatmap({super.key, required this.days});

  final List<DayAmount> days;

  static const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final maxExpense = days.map((d) => d.expense).reduce(math.max);
    // Monday = 1, so a month starting on Wednesday needs 2 empty cells first
    final emptyCells = days.first.date.weekday - 1;

    // On a wide screen (web, tablet) the calendar would be huge without a limit
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: _buildCalendar(theme, color, maxExpense, emptyCells),
      ),
    );
  }

  Widget _buildCalendar(
    ThemeData theme,
    Color color,
    double maxExpense,
    int emptyCells,
  ) {
    return Column(
      children: [
        Row(
          children: [
            for (final name in _weekdays)
              Expanded(
                child: Center(
                  child: Text(name, style: theme.textTheme.labelSmall),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < emptyCells; i++) const SizedBox.shrink(),
            for (final day in days)
              Tooltip(
                message: formatMoney(day.expense),
                child: Container(
                  decoration: BoxDecoration(
                    // 0 spent = light gray, the biggest day = full color
                    color: day.expense == 0
                        ? theme.colorScheme.surfaceContainerHighest
                        : color.withValues(
                            alpha: 0.2 + 0.8 * day.expense / maxExpense,
                          ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.date.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: day.expense > maxExpense / 2
                          ? theme.colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}