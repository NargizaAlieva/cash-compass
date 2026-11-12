import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:cash_compass/features/analytics/ui/analytics_section.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Pie chart of expenses by category + a legend with amounts.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.items,
    required this.categories,
  });

  final List<CategoryAmount> items;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No expenses this month');
    }
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 50,
              sectionsSpace: 2,
              sections: [
                for (final item in items)
                  PieChartSectionData(
                    value: item.amount,
                    color: categoryLook(categories, item.categoryId).color,
                    radius: 45,
                    // Small slices stay without a label, the legend has it
                    title: item.percent >= 8 ? '${item.percent.round()}%' : '',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor:
                      categoryLook(categories, item.categoryId).color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(categoryLook(categories, item.categoryId).name),
                ),
                Text(
                  '${formatMoney(item.amount)}  ·  ${item.percent.round()}%',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}