import 'package:cash_compass/core/ui/category_style.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:flutter/material.dart';

/// What the user entered in the category dialog.
class CategoryFormResult {
  const CategoryFormResult({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final String icon;
  final String color;
}

/// Opens the dialog. Pass [category] to edit it, or nothing to create a new one.
/// Returns null if the user pressed Cancel.
Future<CategoryFormResult?> showCategoryFormDialog(
  BuildContext context, {
  Category? category,
}) {
  return showDialog<CategoryFormResult>(
    context: context,
    builder: (_) => _CategoryFormDialog(category: category),
  );
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.category});

  final Category? category;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.category?.name);
  late String _icon = widget.category?.icon ?? 'category';
  late String _color = widget.category?.color ?? categoryColors.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      CategoryFormResult(
        name: _nameController.text.trim(),
        icon: _icon,
        color: _color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = colorFromHex(_color);

    return AlertDialog(
      title: Text(widget.category == null ? 'New category' : 'Edit category'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(iconFromName(_icon), color: selectedColor),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a name'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text('Icon'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final entry in categoryIcons.entries)
                      IconButton.outlined(
                        isSelected: entry.key == _icon,
                        icon: Icon(entry.value),
                        onPressed: () => setState(() => _icon = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final hex in categoryColors)
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _color = hex),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: colorFromHex(hex),
                          child: hex == _color
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
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