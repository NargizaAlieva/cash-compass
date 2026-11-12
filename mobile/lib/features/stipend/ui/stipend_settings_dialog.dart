import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the stipend settings dialog and saves the result through AuthBloc.
/// Used from Profile and from the stipend card on Home.
Future<void> editStipendSettings(BuildContext context) async {
  final authBloc = context.read<AuthBloc>();
  final user = authBloc.state.user;

  final result = await showDialog<(int, double?)>(
    context: context,
    builder: (_) => _StipendDialog(
      day: user?.stipendDay,
      amount: user?.stipendAmount,
    ),
  );
  if (result != null) {
    final (day, amount) = result;
    authBloc.add(AuthStipendSettingsChanged(stipendDay: day, stipendAmount: amount));
  }
}

class _StipendDialog extends StatefulWidget {
  const _StipendDialog({this.day, this.amount});

  final int? day;
  final double? amount;

  @override
  State<_StipendDialog> createState() => _StipendDialogState();
}

class _StipendDialogState extends State<_StipendDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _day = widget.day;
  late final _amountController = TextEditingController(
    text: widget.amount?.round().toString() ?? '',
  );

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final text = _amountController.text.trim();
    Navigator.pop(context, (_day!, text.isEmpty ? null : parseAmount(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stipend'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _day,
              decoration: const InputDecoration(
                labelText: 'Day of the month',
                helperText: 'If the month is shorter, the last day is used',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
              items: [
                for (var day = 1; day <= 31; day++)
                  DropdownMenuItem(value: day, child: Text('$day')),
              ],
              onChanged: (value) => setState(() => _day = value),
              validator: (value) => value == null ? 'Choose a day' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (optional)',
                suffixText: '₸',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return null;
                }
                final amount = parseAmount(text);
                return amount == null || amount < 0 ? 'Enter a number' : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}