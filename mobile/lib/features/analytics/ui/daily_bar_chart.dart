import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One bar per day. Tap a bar to see the exact amount.
class DailyBarChart extends StatelessWidget {
  const DailyBarChart({super.key, required this.days});

  final List<DayAmount> days;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                // Show 1, 5, 10, 15, ... so the labels do not overlap
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  final show = day == 1 || day % 5 == 0;
                  return show
                      ? Text('$day', style: labelStyle)
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${group.x} · ${formatMoney(rod.toY)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
            ),
          ),
          barGroups: [
            for (final day in days)
              BarChartGroupData(
                x: day.date.day,
                barRods: [
                  BarChartRodData(
                    toY: day.expense,
                    color: color,
                    width: 6,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}