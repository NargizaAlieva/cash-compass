import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/features/categories/data/category.dart';

class CategoriesRepository {
  CategoriesRepository(this._api);

  final ApiClient _api;

  Future<List<Category>> fetchCategories() async {
    final data = await _api.get('/categories') as List<dynamic>;
    return data
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCategory({
    required String name,
    required CategoryKind kind,
    required String icon,
    required String color,
  }) =>
      _api.post(
        '/categories',
        data: {'name': name, 'kind': kind.name, 'icon': icon, 'color': color},
      );

  Future<void> updateCategory(
    int id, {
    required String name,
    required String icon,
    required String color,
  }) =>
      _api.put(
        '/categories/$id',
        data: {'name': name, 'icon': icon, 'color': color},
      );

  Future<void> deleteCategory(int id) => _api.delete('/categories/$id');
}