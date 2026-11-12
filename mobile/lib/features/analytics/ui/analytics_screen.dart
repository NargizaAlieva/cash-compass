import 'package:cash_compass/core/ui/error_view.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/analytics/bloc/analytics_bloc.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:cash_compass/features/analytics/ui/analytics_section.dart';
import 'package:cash_compass/features/analytics/ui/anomalies_block.dart';
import 'package:cash_compass/features/analytics/ui/category_changes_block.dart';
import 'package:cash_compass/features/analytics/ui/category_pie_chart.dart';
import 'package:cash_compass/features/analytics/ui/daily_bar_chart.dart';
import 'package:cash_compass/features/analytics/ui/impulse_block.dart';
import 'package:cash_compass/features/analytics/ui/spending_heatmap.dart';
import 'package:cash_compass/features/analytics/ui/what_if_block.dart';
import 'package:cash_compass/features/categories/bloc/categories_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

const _incomeColor = Color(0xFF2E7D32);

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: BlocConsumer<AnalyticsBloc, AnalyticsState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          final data = state.data;
          // Old data of another month must not be shown under the new title
          final hasDataForMonth = data != null &&
              data.month == DateFormat('yyyy-MM').format(state.month);

          final Widget body;
          if (hasDataForMonth) {
            body = _AnalyticsContent(data: data);
          } else if (state.status == AnalyticsStatus.failure) {
            body = ErrorView(
              message: state.errorMessage ?? 'Could not load analytics',
              onRetry: () => context
                  .read<AnalyticsBloc>()
                  .add(const AnalyticsRequested()),
            );
          } else {
            body = const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _MonthSwitcher(state: state),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}

/// ‹  November 2026  ›
class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AnalyticsBloc>();
    final isCurrent = state.isCurrentMonth(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => bloc.add(const AnalyticsMonthShifted(-1)),
        ),
        SizedBox(
          width: 160,
          child: Text(
            DateFormat('MMMM yyyy').format(state.month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
          // There is nothing to analyze in the future
          onPressed:
              isCurrent ? null : () => bloc.add(const AnalyticsMonthShifted(1)),
        ),
      ],
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.data});

  final MonthAnalytics data;

  @override
  Widget build(BuildContext context) {
    final categories =
        context.select((CategoriesBloc bloc) => bloc.state.categories);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            _NumberCard(
              label: 'Income',
              value: formatMoney(data.income),
              color: _incomeColor,
            ),
            _NumberCard(
              label: 'Expenses',
              value: formatMoney(data.expense),
              color: Theme.of(context).colorScheme.error,
            ),
            _NumberCard(
              label: 'Left',
              value: formatMoney(data.net),
              // Spent more than earned this month
              color: data.net < 0 ? Theme.of(context).colorScheme.error : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnalyticsSection(title: 'Overview', child: _Overview(data: data)),
        AnalyticsSection(
          title: 'Unusual spending',
          child: AnomaliesBlock(
            anomalies: data.anomalies,
            categories: categories,
          ),
        ),
        AnalyticsSection(
          title: 'Spending by category',
          child: CategoryPieChart(
            items: data.byCategory,
            categories: categories,
          ),
        ),
        AnalyticsSection(
          title: 'Spending by day',
          child: DailyBarChart(days: data.daily),
        ),
        AnalyticsSection(
          title: 'Spending calendar',
          child: SpendingHeatmap(days: data.daily),
        ),
        AnalyticsSection(
          title: 'Needed vs wanted',
          child: ImpulseBlock(impulse: data.impulse),
        ),
        AnalyticsSection(
          title: 'What if I spend less?',
          child: WhatIfBlock(
            byCategory: data.byCategory,
            categories: categories,
          ),
        ),
        AnalyticsSection(
          title: 'Compared to last month',
          child: CategoryChangesBlock(
            changes: data.categoryChanges,
            categories: categories,
          ),
        ),
      ],
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Average per day, forecast and change vs last month.
class _Overview extends StatelessWidget {
  const _Overview({required this.data});

  final MonthAnalytics data;

  @override
  Widget build(BuildContext context) {
    final change = data.expenseChangePercent;
    final forecast = data.forecastExpense;

    return Column(
      children: [
        _OverviewRow(
          icon: Icons.today,
          text: 'On average '
              '${formatMoney(data.avgDailyExpense.roundToDouble())} a day',
        ),
        if (forecast != null)
          _OverviewRow(
            icon: Icons.trending_up,
            text: 'At this pace: about '
                '${formatMoney(forecast.roundToDouble())} '
                'by the end of the month',
          ),
        if (change != null)
          _OverviewRow(
            icon: change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
            color: change > 0
                ? Theme.of(context).colorScheme.error
                : _incomeColor,
            text: '${change > 0 ? '+' : '−'}${change.abs().round()}% '
                'vs last month (${formatMoney(data.previousExpense)})',
          ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}