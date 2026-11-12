import 'package:cash_compass/features/categories/data/category.dart';
import 'package:equatable/equatable.dart';

sealed class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) categories from the server.
final class CategoriesRequested extends CategoriesEvent {
  const CategoriesRequested();
}

final class CategoryAdded extends CategoriesEvent {
  const CategoryAdded({
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
  });

  final String name;
  final CategoryKind kind;
  final String icon;
  final String color;

  @override
  List<Object?> get props => [name, kind, icon, color];
}

final class CategoryUpdated extends CategoriesEvent {
  const CategoryUpdated({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final int id;
  final String name;
  final String icon;
  final String color;

  @override
  List<Object?> get props => [id, name, icon, color];
}

final class CategoryDeleted extends CategoriesEvent {
  const CategoryDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}