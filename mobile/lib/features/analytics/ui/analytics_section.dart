import 'package:cash_compass/core/ui/category_style.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:flutter/material.dart';

/// A card with a title. Every block on the Analytics screen uses it.
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Name, color and icon of a category by its id.
/// The server sends only ids, so the names come from CategoriesBloc.
({String name, Color color, IconData icon}) categoryLook(
  List<Category> categories,
  int? categoryId,
) {
  final category = categories.where((c) => c.id == categoryId).firstOrNull;
  if (category == null) {
    return (name: 'No category', color: Colors.grey, icon: Icons.category);
  }
  return (
    name: category.name,
    color: colorFromHex(category.color),
    icon: iconFromName(category.icon),
  );
}