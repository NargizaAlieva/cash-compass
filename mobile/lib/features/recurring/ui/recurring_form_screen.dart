import 'package:cash_compass/core/ui/category_style.dart';
import 'package:cash_compass/core/ui/confirm_dialog.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/accounts/data/account.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:cash_compass/features/recurring/data/recurring_payment.dart';
import 'package:flutter/material.dart';

/// What the form returns: a draft to save, or a request to delete.
class RecurringFormResult {
  const RecurringFormResult.save(RecurringDraft this.draft) : delete = false;

  const RecurringFormResult.delete() : draft = null, delete = true;

  final RecurringDraft? draft;
  final bool delete;
}

/// Full-screen form to add or edit a regular payment.
class RecurringFormScreen extends StatefulWidget {
  const RecurringFormScreen({
    super.key,
    required this.accounts,
    required this.categories,
    this.payment,
  });

  final List<Account> accounts;

  /// Only expense categories are shown.
  final List<Category> categories;

  /// null = new payment.
  final RecurringPayment? payment;

  @override
  State<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends State<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final RecurringPayment? _old = widget.payment;
  late final _nameController = TextEditingController(text: _old?.name ?? '');
  late final _amountController = TextEditingController(
    text: _old == null ? '' : _old.amount.round().toString(),
  );
  late int? _accountId = _old?.accountId ?? widget.accounts.first.id;
  late int? _categoryId = _old?.categoryId;
  late int? _day = _old?.dayOfMonth ?? DateTime.now().day;
  bool _showCategoryError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete regular payment?',
      message: 'Expenses that were already created stay in the history.',
    );
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context, const RecurringFormResult.delete());
  }

  void _save() {
    final fieldsValid = _formKey.currentState!.validate();
    setState(() => _showCategoryError = _categoryId == null);
    if (!fieldsValid || _categoryId == null) {
      return;
    }
    Navigator.pop(
      context,
      RecurringFormResult.save(
        RecurringDraft(
          name: _nameController.text.trim(),
          amount: parseAmount(_amountController.text)!,
          accountId: _accountId!,
          categoryId: _categoryId!,
          dayOfMonth: _day!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories =
        widget.categories.where((c) => c.kind == CategoryKind.expense).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_old == null ? 'New regular payment' : 'Edit regular payment'),
        actions: [
          if (_old != null)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: _old == null,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Spotify, Dormitory, Phone',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount every month',
                suffixText: 'som',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = parseAmount(value ?? '');
                return amount == null || amount <= 0
                    ? 'Enter an amount greater than 0'
                    : null;
              },
            ),
            const SizedBox(height: 16),
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
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _accountId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pay from',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final account in widget.accounts)
                  DropdownMenuItem(value: account.id, child: Text(account.name)),
              ],
              onChanged: (value) => setState(() => _accountId = value),
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  ChoiceChip(
                    avatar: Icon(
                      iconFromName(category.icon),
                      color: colorFromHex(category.color),
                      size: 18,
                    ),
                    label: Text(category.name),
                    selected: _categoryId == category.id,
                    onSelected: (_) => setState(() {
                      _categoryId = category.id;
                      _showCategoryError = false;
                    }),
                  ),
              ],
            ),
            if (_showCategoryError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Choose a category',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
