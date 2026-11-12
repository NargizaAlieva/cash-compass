import 'package:cash_compass/core/ui/category_style.dart';
import 'package:cash_compass/core/ui/confirm_dialog.dart';
import 'package:cash_compass/core/ui/error_view.dart';
import 'package:cash_compass/features/categories/bloc/categories_bloc.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:cash_compass/features/categories/ui/category_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Categories in two tabs: Expenses and Income.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _tabKinds = [CategoryKind.expense, CategoryKind.income];

  Future<void> _addCategory(BuildContext context, CategoryKind kind) async {
    final bloc = context.read<CategoriesBloc>();
    final result = await showCategoryFormDialog(context);
    if (result != null) {
      bloc.add(
        CategoryAdded(
          name: result.name,
          kind: kind,
          icon: result.icon,
          color: result.color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabKinds.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Expenses'), Tab(text: 'Income')],
          ),
        ),
        // Builder gives a context that is below DefaultTabController
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            tooltip: 'Add category',
            onPressed: () => _addCategory(
              context,
              _tabKinds[DefaultTabController.of(context).index],
            ),
            child: const Icon(Icons.add),
          ),
        ),
        body: BlocConsumer<CategoriesBloc, CategoriesState>(
          listenWhen: (previous, current) =>
              current.errorMessage != null &&
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          },
          builder: (context, state) {
            final nothingLoadedYet = state.categories.isEmpty;

            if (state.status == CategoriesStatus.initial ||
                (state.status == CategoriesStatus.loading &&
                    nothingLoadedYet)) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == CategoriesStatus.failure && nothingLoadedYet) {
              return ErrorView(
                message: state.errorMessage ?? 'Could not load categories',
                onRetry: () => context
                    .read<CategoriesBloc>()
                    .add(const CategoriesRequested()),
              );
            }

            return TabBarView(
              children: [
                for (final kind in _tabKinds)
                  _CategoryList(categories: state.byKind(kind)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: categories.length,
      itemBuilder: (context, index) =>
          _CategoryTile(category: categories[index]),
    );
  }
}

enum _CategoryAction { edit, delete }

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final Category category;

  Future<void> _onAction(BuildContext context, _CategoryAction action) async {
    final bloc = context.read<CategoriesBloc>();

    switch (action) {
      case _CategoryAction.edit:
        final result =
            await showCategoryFormDialog(context, category: category);
        if (result != null) {
          bloc.add(
            CategoryUpdated(
              id: category.id,
              name: result.name,
              icon: result.icon,
              color: result.color,
            ),
          );
        }
      case _CategoryAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete category?',
          message: '"${category.name}" will be deleted.',
        );
        if (confirmed) {
          bloc.add(CategoryDeleted(category.id));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(category.color);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(iconFromName(category.icon), color: color),
      ),
      title: Text(category.name),
      trailing: PopupMenuButton<_CategoryAction>(
        onSelected: (action) => _onAction(context, action),
        itemBuilder: (_) => const [
          PopupMenuItem(value: _CategoryAction.edit, child: Text('Edit')),
          PopupMenuItem(value: _CategoryAction.delete, child: Text('Delete')),
        ],
      ),
    );
  }
}