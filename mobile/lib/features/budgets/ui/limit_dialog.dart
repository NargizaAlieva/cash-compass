import 'package:cash_compass/core/ui/formatters.dart';
import 'package:flutter/material.dart';

/// Asks for a monthly limit. Returns the amount, or null if cancelled.
Future<double?> showLimitDialog(
  BuildContext context, {
  required String categoryName,
  double? currentLimit,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _LimitDialog(
      categoryName: categoryName,
      currentLimit: currentLimit,
    ),
  );
}

class _LimitDialog extends StatefulWidget {
  const _LimitDialog({required this.categoryName, this.currentLimit});

  final String categoryName;
  final double? currentLimit;

  @override
  State<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<_LimitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.currentLimit?.round().toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, parseAmount(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Limit for ${widget.categoryName}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onFieldSubmitted: (_) => _save(),
          decoration: const InputDecoration(
            labelText: 'Per month',
            suffixText: '₸',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final amount = parseAmount(value ?? '');
            if (amount == null || amount <= 0) {
              return 'Enter an amount greater than 0';
            }
            return null;
          },
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