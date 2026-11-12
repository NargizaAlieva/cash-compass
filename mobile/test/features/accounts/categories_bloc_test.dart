import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/categories/bloc/categories_bloc.dart';
import 'package:cash_compass/features/categories/data/categories_repository.dart';
import 'package:cash_compass/features/categories/data/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

const food = Category(
  id: 1,
  name: 'Food',
  kind: CategoryKind.expense,
  icon: 'restaurant',
  color: '#EF6C00',
);
const stipend = Category(
  id: 2,
  name: 'Stipend',
  kind: CategoryKind.income,
  icon: 'school',
  color: '#2E7D32',
);

void main() {
  late MockCategoriesRepository repository;

  setUpAll(() {
    registerFallbackValue(CategoryKind.expense);
  });

  setUp(() {
    repository = MockCategoriesRepository();
  });

  test('byKind splits expenses and income', () {
    const state = CategoriesState(categories: [food, stipend]);
    expect(state.byKind(CategoryKind.expense), [food]);
    expect(state.byKind(CategoryKind.income), [stipend]);
  });

  blocTest<CategoriesBloc, CategoriesState>(
    'CategoriesRequested loads categories',
    build: () {
      when(() => repository.fetchCategories())
          .thenAnswer((_) async => [food, stipend]);
      return CategoriesBloc(repository);
    },
    act: (bloc) => bloc.add(const CategoriesRequested()),
    expect: () => [
      const CategoriesState(status: CategoriesStatus.loading),
      const CategoriesState(
        status: CategoriesStatus.success,
        categories: [food, stipend],
      ),
    ],
  );

  blocTest<CategoriesBloc, CategoriesState>(
    'CategoryAdded shows the server error for a duplicate name',
    build: () {
      when(
        () => repository.createCategory(
          name: any(named: 'name'),
          kind: any(named: 'kind'),
          icon: any(named: 'icon'),
          color: any(named: 'color'),
        ),
      ).thenThrow(
        const ApiException(
          'Category with this name already exists',
          statusCode: 409,
        ),
      );
      return CategoriesBloc(repository);
    },
    seed: () => const CategoriesState(
      status: CategoriesStatus.success,
      categories: [food],
    ),
    act: (bloc) => bloc.add(
      const CategoryAdded(
        name: 'Food',
        kind: CategoryKind.expense,
        icon: 'restaurant',
        color: '#EF6C00',
      ),
    ),
    expect: () => [
      const CategoriesState(
        status: CategoriesStatus.success,
        categories: [food],
        errorMessage: 'Category with this name already exists',
      ),
    ],
  );

  blocTest<CategoriesBloc, CategoriesState>(
    'CategoryDeleted deletes and reloads',
    build: () {
      when(() => repository.deleteCategory(1)).thenAnswer((_) async {});
      when(() => repository.fetchCategories())
          .thenAnswer((_) async => [stipend]);
      return CategoriesBloc(repository);
    },
    seed: () => const CategoriesState(
      status: CategoriesStatus.success,
      categories: [food, stipend],
    ),
    act: (bloc) => bloc.add(const CategoryDeleted(1)),
    expect: () => [
      const CategoriesState(
        status: CategoriesStatus.success,
        categories: [stipend],
      ),
    ],
    verify: (_) => verify(() => repository.deleteCategory(1)).called(1),
  );
}