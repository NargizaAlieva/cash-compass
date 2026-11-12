import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:cash_compass/features/analytics/ui/analytics_section.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:flutter/material.dart';

/// "Transport: 6 500 som on 5 Nov, 4.3x your usual 1 500 som".
class AnomaliesBlock extends StatelessWidget {
  const AnomaliesBlock({
    super.key,
    required this.anomalies,
    required this.categories,
  });

  final List<Anomaly> anomalies;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (anomalies.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Expanded(child: Text('Nothing unusual this month')),
        ],
      );
    }
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final anomaly in anomalies)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              categoryLook(categories, anomaly.categoryId).icon,
              color: categoryLook(categories, anomaly.categoryId).color,
            ),
            title: Text(
              anomaly.isPurchase
                  ? '${formatMoney(anomaly.amount)} on '
                      '${formatDay(anomaly.date ?? DateTime.now())}'
                  : '${formatMoney(anomaly.amount)} this month',
            ),
            subtitle: Text(
              '${categoryLook(categories, anomaly.categoryId).name}: '
              '${anomaly.times}x your usual '
              '${anomaly.isPurchase ? 'purchase' : 'month'} '
              '(${formatMoney(anomaly.usual.roundToDouble())})',
            ),
            trailing: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          ),
      ],
    );
  }
}
