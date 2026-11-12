import 'package:cash_compass/core/ui/category_style.dart';
import 'package:cash_compass/core/ui/confirm_dialog.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/accounts/data/account.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:cash_compass/features/transactions/data/transaction.dart';
import 'package:flutter/material.dart';

/// What the form returns: a draft to save, or a request to delete.
class TransactionFormResult {
  const TransactionFormResult.save(TransactionDraft this.draft)
    : delete = false;

  const TransactionFormResult.delete() : draft = null, delete = true;

  final TransactionDraft? draft;
  final bool delete;
}

/// Full-screen form to add or edit a transaction.
///
/// It gets accounts and categories as parameters and returns the result
/// with Navigator.pop. It does not talk to Blocs itself.
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({
    super.key,
    required this.accounts,
    required this.categories,
    this.transaction,
  });

  final List<Account> accounts;
  final List<Category> categories;

  /// null = new transaction, otherwise we edit this one.
  final Transaction? transaction;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final Transaction? _old = widget.transaction;
  late final _amountController = TextEditingController(
    text: _old == null ? '' : _amountToText(_old.amount),
  );
  late final _noteController = TextEditingController(text: _old?.note ?? '');

  late TransactionKind _kind = _old?.kind ?? TransactionKind.expense;
  late int? _accountId = _old?.accountId ?? widget.accounts.first.id;
  late int? _toAccountId = _old?.toAccountId;
  late int? _categoryId = _old?.categoryId;
  late DateTime _date = _old?.date ?? DateUtils.dateOnly(DateTime.now());
  late bool _isImpulsive = _old?.isImpulsive ?? false;
  bool _showCategoryError = false;

  bool get _isEdit => _old != null;

  /// 2500.0 -> "2500", 99.5 -> "99.5"
  static String _amountToText(double amount) => amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toString();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _changeKind(TransactionKind kind) {
    setState(() {
      _kind = kind;
      _categoryId = null; // expense and income categories are different
      _showCategoryError = false;
      if (kind != TransactionKind.expense) {
        _isImpulsive = false;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete transaction?',
      message: 'The account balance will be restored.',
    );
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context, const TransactionFormResult.delete());
  }

  void _save() {
    final fieldsValid = _formKey.currentState!.validate();
    final needsCategory = _kind != TransactionKind.transfer;
    final categoryMissing = needsCategory && _categoryId == null;
    setState(() => _showCategoryError = categoryMissing);
    if (!fieldsValid || categoryMissing) {
      return;
    }

    final draft = TransactionDraft(
      kind: _kind,
      amount: parseAmount(_amountController.text)!,
      accountId: _accountId!,
      toAccountId: _kind == TransactionKind.transfer ? _toAccountId : null,
      categoryId: needsCategory ? _categoryId : null,
      date: _date,
      note: _noteController.text.trim(),
      isImpulsive: _kind == TransactionKind.expense && _isImpulsive,
    );
    Navigator.pop(context, TransactionFormResult.save(draft));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTransfer = _kind == TransactionKind.transfer;
    final categoryKind = _kind == TransactionKind.income
        ? CategoryKind.income
        : CategoryKind.expense;
    final categories = widget.categories
        .where((c) => c.kind == categoryKind)
        .toList();

    final accountItems = [
      for (final account in widget.accounts)
        DropdownMenuItem(
          value: account.id,
          child: Text('${account.name} · ${formatMoney(account.balance)}'),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit transaction' : 'New transaction'),
        actions: [
          if (_isEdit)
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
            SegmentedButton<TransactionKind>(
              segments: const [
                ButtonSegment(
                  value: TransactionKind.expense,
                  icon: Icon(Icons.arrow_upward),
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: TransactionKind.income,
                  icon: Icon(Icons.arrow_downward),
                  label: Text('Income'),
                ),
                ButtonSegment(
                  value: TransactionKind.transfer,
                  icon: Icon(Icons.swap_horiz),
                  label: Text('Transfer'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) => _changeKind(selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              autofocus: !_isEdit,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineSmall,
              decoration: const InputDecoration(
                labelText: 'Amount',
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
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _accountId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: isTransfer ? 'From account' : 'Account',
                border: const OutlineInputBorder(),
              ),
              items: accountItems,
              onChanged: (value) => setState(() => _accountId = value),
              validator: (value) => value == null ? 'Choose an account' : null,
            ),
            if (isTransfer) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _toAccountId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'To account',
                  border: OutlineInputBorder(),
                ),
                items: accountItems,
                onChanged: (value) => setState(() => _toAccountId = value),
                validator: (value) {
                  if (value == null) {
                    return 'Choose an account';
                  }
                  if (value == _accountId) {
                    return 'Choose a different account';
                  }
                  return null;
                },
              ),
            ] else ...[
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
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(formatDay(_date)),
              subtitle: const Text('Date'),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _noteController,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_kind == TransactionKind.expense)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.bolt),
                title: const Text('Impulse purchase'),
                subtitle: const Text('I wanted it, but did not really need it'),
                value: _isImpulsive,
                onChanged: (value) => setState(() => _isImpulsive = value),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}