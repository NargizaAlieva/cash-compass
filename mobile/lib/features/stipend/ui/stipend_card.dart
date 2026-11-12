import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/stipend/bloc/stipend_bloc.dart';
import 'package:cash_compass/features/stipend/data/stipend_allowance.dart';
import 'package:cash_compass/features/stipend/ui/stipend_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// "Today you can spend 3 200 ₸ · 13 days until the stipend".
class StipendCard extends StatelessWidget {
  const StipendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final allowance =
        context.select((StipendBloc bloc) => bloc.state.allowance);

    if (allowance == null) {
      return const SizedBox.shrink(); // not loaded yet
    }
    if (!allowance.configured) {
      return const _SetUpCard();
    }
    return _AllowanceCard(allowance: allowance);
  }
}

/// Shown until the user sets the stipend day.
class _SetUpCard extends StatelessWidget {
  const _SetUpCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.school_outlined),
        title: const Text('How much can I spend today?'),
        subtitle: const Text('Set your stipend day to see a daily budget'),
        trailing: TextButton(
          onPressed: () => editStipendSettings(context),
          child: const Text('Set up'),
        ),
      ),
    );
  }
}

class _AllowanceCard extends StatelessWidget {
  const _AllowanceCard({required this.allowance});

  final StipendAllowance allowance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daily = allowance.dailyAllowance ?? 0;
    final spent = allowance.spentToday ?? 0;
    final left = allowance.leftToday ?? 0;
    final days = allowance.daysLeft ?? 0;
    final isOver = left < 0;
    final barColor = isOver ? theme.colorScheme.error : theme.colorScheme.primary;
    final nextDate = allowance.nextStipendDate;

    return Card(
      color: theme.colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => editStipendSettings(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOver ? 'Over today\'s budget by' : 'You can spend today',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(left.abs().roundToDouble()),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOver ? theme.colorScheme.error : null,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: daily == 0 ? 1 : (spent / daily).clamp(0, 1),
                  minHeight: 6,
                  color: barColor,
                  backgroundColor: barColor.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spent ${formatMoney(spent)} of '
                '${formatMoney(daily.roundToDouble())} for today',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.school_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$days ${days == 1 ? 'day' : 'days'} until the stipend'
                      '${nextDate == null ? '' : ' (${DateFormat('d MMM').format(nextDate)})'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}