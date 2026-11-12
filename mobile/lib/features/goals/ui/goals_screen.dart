import 'package:cash_compass/core/ui/confirm_dialog.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/goals/bloc/goals_bloc.dart';
import 'package:cash_compass/features/goals/data/goal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Opens the goals screen on top of MainShell with the existing GoalsBloc.
void openGoalsScreen(BuildContext context) {
  final bloc = context.read<GoalsBloc>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: bloc, child: const GoalsScreen()),
    ),
  );
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _edit(BuildContext context, {Goal? goal}) async {
    final bloc = context.read<GoalsBloc>();
    final draft = await showDialog<GoalDraft>(
      context: context,
      builder: (_) => _GoalDialog(goal: goal),
    );
    if (draft == null) {
      return;
    }
    bloc.add(goal == null ? GoalAdded(draft) : GoalUpdated(goal.id, draft));
  }

  Future<void> _delete(BuildContext context, Goal goal) async {
    final bloc = context.read<GoalsBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete goal?',
      message: '"${goal.name}" will be deleted.',
    );
    if (confirmed) {
      bloc.add(GoalDeleted(goal.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: BlocConsumer<GoalsBloc, GoalsState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!))),
        builder: (context, state) {
          if (state.status == GoalsStatus.initial ||
              (state.status == GoalsStatus.loading && state.goals.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                state.monthlySaving > 0
                    ? 'You save about ${formatMoney(state.monthlySaving.roundToDouble())} '
                        'a month (average of the last 3 months).'
                    : 'Lately you spend all your income, so goals have no forecast yet.',
              ),
              const SizedBox(height: 12),
              if (state.goals.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No goals yet. Add one: a laptop, a trip, a gift...',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final goal in state.goals)
                _GoalCard(
                  goal: goal,
                  onEdit: () => _edit(context, goal: goal),
                  onDelete: () => _delete(context, goal),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecast = goal.forecastDate;
    final String forecastText;
    if (goal.achieved) {
      forecastText = 'Goal reached!';
    } else if (forecast == null) {
      forecastText = 'No forecast: you do not save anything now';
    } else {
      forecastText = 'At this pace: ${DateFormat('MMMM yyyy').format(forecast)} '
          '(${goal.monthsLeft} ${goal.monthsLeft == 1 ? 'month' : 'months'})';
    }

    return Card(
      child: InkWell(
        onTap: onEdit,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(goal.achieved ? Icons.emoji_events : Icons.flag_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(goal.name, style: theme.textTheme.titleMedium)),
                  Text('${goal.percent.round()}%', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: goal.percent / 100, minHeight: 8),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatMoney(goal.savedAmount)} of ${formatMoney(goal.targetAmount)}',
              ),
              Text(forecastText, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Name, target and how much is already saved. Returns a draft or null.
class _GoalDialog extends StatefulWidget {
  const _GoalDialog({this.goal});

  final Goal? goal;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.goal?.name ?? '');
  late final _target =
      TextEditingController(text: widget.goal?.targetAmount.round().toString() ?? '');
  late final _saved =
      TextEditingController(text: widget.goal?.savedAmount.round().toString() ?? '0');

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  String? _amountValidator(String? value, {required bool allowZero}) {
    final amount = parseAmount(value ?? '');
    if (amount == null || amount < 0 || (!allowZero && amount == 0)) {
      return 'Enter a correct amount';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goal == null ? 'New goal' : 'Edit goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: widget.goal == null,
              decoration: const InputDecoration(labelText: 'What for', hintText: 'Laptop'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            TextFormField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target', suffixText: '₸'),
              validator: (v) => _amountValidator(v, allowZero: false),
            ),
            TextFormField(
              controller: _saved,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Already saved', suffixText: '₸'),
              validator: (v) => _amountValidator(v, allowZero: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.pop(
              context,
              GoalDraft(
                name: _name.text.trim(),
                targetAmount: parseAmount(_target.text)!,
                savedAmount: parseAmount(_saved.text)!,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
