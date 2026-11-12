import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:cash_compass/features/analytics/ui/analytics_section.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:flutter/material.dart';

/// Categories where the user spent more or less than last month.
class CategoryChangesBlock extends StatelessWidget {
  const CategoryChangesBlock({
    super.key,
    required this.changes,
    required this.categories,
  });

  final List<CategoryChange> changes;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    // The server already sorted them: the biggest change first
    final visible = changes.where((c) => c.change != 0).take(5).toList();
    if (visible.isEmpty) {
      return const Text('Same as last month');
    }
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final item in visible)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              categoryLook(categories, item.categoryId).icon,
              color: categoryLook(categories, item.categoryId).color,
            ),
            title: Text(categoryLook(categories, item.categoryId).name),
            subtitle: Text(
              '${formatMoney(item.previous)} → ${formatMoney(item.current)}',
            ),
            trailing: Text(
              // Spending more is bad (red), spending less is good (green)
              '${item.change > 0 ? '+' : '−'}${formatMoney(item.change.abs())}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: item.change > 0
                    ? theme.colorScheme.error
                    : const Color(0xFF2E7D32),
              ),
            ),
          ),
      ],
    );
  }
}