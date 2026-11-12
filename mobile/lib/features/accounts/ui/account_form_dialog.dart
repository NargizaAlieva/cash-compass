import 'package:cash_compass/features/accounts/data/account.dart';
import 'package:flutter/material.dart';

/// What the user entered in the account dialog.
class AccountFormResult {
  const AccountFormResult({
    required this.name,
    required this.type,
    required this.balance,
  });

  final String name;
  final AccountType type;
  final double balance;
}

/// Opens the dialog. Pass [account] to edit it, or nothing to create a new one.
/// Returns null if the user pressed Cancel.
Future<AccountFormResult?> showAccountFormDialog(
  BuildContext context, {
  Account? account,
}) {
  return showDialog<AccountFormResult>(
    context: context,
    builder: (_) => _AccountFormDialog(account: account),
  );
}

class _AccountFormDialog extends StatefulWidget {
  const _AccountFormDialog({this.account});

  final Account? account;

  @override
  State<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<_AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.account?.name);
  final _balanceController = TextEditingController(text: '0');
  late AccountType _type = widget.account?.type ?? AccountType.card;

  bool get _isEdit => widget.account != null;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  /// Accepts "15 000", "1500,50" and "1500.50".
  double? _parseAmount(String text) =>
      double.tryParse(text.replaceAll(' ', '').replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      AccountFormResult(
        name: _nameController.text.trim(),
        type: _type,
        balance: _isEdit ? 0 : _parseAmount(_balanceController.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit account' : 'New account'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Kaspi Gold',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<AccountType>(
              segments: const [
                ButtonSegment(
                  value: AccountType.cash,
                  icon: Icon(Icons.payments_outlined),
                  label: Text('Cash'),
                ),
                ButtonSegment(
                  value: AccountType.card,
                  icon: Icon(Icons.credit_card),
                  label: Text('Card'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            // The balance is set only once. Later it changes through transactions.
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current balance',
                  suffixText: '₸',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    _parseAmount(value ?? '') == null ? 'Enter a number' : null,
              ),
            ],
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