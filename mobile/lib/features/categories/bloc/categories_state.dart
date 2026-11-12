import 'package:cash_compass/features/categories/data/category.dart';
import 'package:equatable/equatable.dart';

enum CategoriesStatus { initial, loading, success, failure }

class CategoriesState extends Equatable {
  const CategoriesState({
    this.status = CategoriesStatus.initial,
    this.categories = const [],
    this.errorMessage,
  });

  final CategoriesStatus status;
  final List<Category> categories;

  /// Error to show once (as a SnackBar).
  final String? errorMessage;

  List<Category> byKind(CategoryKind kind) =>
      categories.where((category) => category.kind == kind).toList();

  /// Note: errorMessage is NOT copied, so every new state clears the old error.
  CategoriesState copyWith({
    CategoriesStatus? status,
    List<Category>? categories,
    String? errorMessage,
  }) {
    return CategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, categories, errorMessage];
}