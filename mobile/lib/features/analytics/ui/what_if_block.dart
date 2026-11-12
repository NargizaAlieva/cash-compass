import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/analytics/data/month_analytics.dart';
import 'package:cash_compass/features/analytics/ui/analytics_section.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:cash_compass/features/goals/bloc/goals_bloc.dart';
import 'package:cash_compass/features/goals/data/goal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "What if I spend 30% less on Food?" -> money per month and per year,
/// and how much sooner the first goal is reached.
///
/// Everything is calculated on the phone from data that is already loaded,
/// so moving the slider is instant. The chosen category and percent are
/// pure screen state, so setState is enough here.
class WhatIfBlock extends StatefulWidget {
  const WhatIfBlock({super.key, required this.byCategory, required this.categories});

  final List<CategoryAmount> byCategory;
  final List<Category> categories;

  @override
  State<WhatIfBlock> createState() => _WhatIfBlockState();
}

class _WhatIfBlockState extends State<WhatIfBlock> {
  int? _categoryId;
  double _percent = 30;

  @override
  Widget build(BuildContext context) {
    final items = widget.byCategory.where((c) => c.categoryId != null).toList();
    if (items.isEmpty) {
      return const Text('Add some expenses to try it');
    }
    final selected =
        items.where((c) => c.categoryId == _categoryId).firstOrNull ?? items.first;
    final monthlyCut = selected.amount * _percent / 100;

    final goals = context.select((GoalsBloc bloc) => bloc.state.goals);
    final saving = context.select((GoalsBloc bloc) => bloc.state.monthlySaving);
    final goal = goals.where((g) => !g.achieved).firstOrNull;
    final theme = Theme.of(context);

    String? goalText;
    if (goal != null) {
      final now = monthsToCollect(goal.remaining, saving);
      final after = monthsToCollect(goal.remaining, saving + monthlyCut);
      if (after != null && now == null) {
        goalText = '"${goal.name}" would be reached in $after months';
      } else if (after != null && now != null && after < now) {
        goalText = '"${goal.name}" ${now - after} months sooner '
            '($after instead of $now)';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<int>(
          value: selected.categoryId,
          isExpanded: true,
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item.categoryId,
                child: Text(
                  '${categoryLook(widget.categories, item.categoryId).name} · '
                  '${formatMoney(item.amount)}',
                ),
              ),
          ],
          onChanged: (value) => setState(() => _categoryId = value),
        ),
        Row(
          children: [
            const Text('Spend less by'),
            Expanded(
              child: Slider(
                value: _percent,
                max: 100,
                divisions: 20,
                label: '${_percent.round()}%',
                onChanged: (value) => setState(() => _percent = value),
              ),
            ),
            Text('${_percent.round()}%'),
          ],
        ),
        Text(
          '+${formatMoney(monthlyCut.roundToDouble())} a month · '
          '+${formatMoney((monthlyCut * 12).roundToDouble())} a year',
          style: theme.textTheme.titleMedium,
        ),
        if (goalText != null) ...[
          const SizedBox(height: 4),
          Text(goalText),
        ],
      ],
    );
  }
}
