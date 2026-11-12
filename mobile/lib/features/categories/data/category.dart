import 'package:equatable/equatable.dart';

enum CategoryKind { expense, income }

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        kind: CategoryKind.values.byName(json['kind'] as String),
        icon: json['icon'] as String,
        color: json['color'] as String,
      );

  final int id;
  final String name;
  final CategoryKind kind;

  /// Icon name, e.g. "restaurant" (see core/ui/category_style.dart).
  final String icon;

  /// Color in "#RRGGBB" format.
  final String color;

  @override
  List<Object?> get props => [id, name, kind, icon, color];
}