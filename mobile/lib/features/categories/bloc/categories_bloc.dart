import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/categories/bloc/categories_event.dart';
import 'package:cash_compass/features/categories/bloc/categories_state.dart';
import 'package:cash_compass/features/categories/data/categories_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'categories_event.dart';
export 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc(this._repository) : super(const CategoriesState()) {
    on<CategoriesRequested>(_onRequested);
    on<CategoryAdded>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.createCategory(
          name: event.name,
          kind: event.kind,
          icon: event.icon,
          color: event.color,
        ),
      ),
    );
    on<CategoryUpdated>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.updateCategory(
          event.id,
          name: event.name,
          icon: event.icon,
          color: event.color,
        ),
      ),
    );
    on<CategoryDeleted>(
      (event, emit) => _changeAndReload(
        emit,
        () => _repository.deleteCategory(event.id),
      ),
    );
  }

  final CategoriesRepository _repository;

  Future<void> _onRequested(
    CategoriesRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(status: CategoriesStatus.loading));
    await _load(emit);
  }

  /// Sends a change to the server, then reloads the list.
  Future<void> _changeAndReload(
    Emitter<CategoriesState> emit,
    Future<void> Function() change,
  ) async {
    emit(state.copyWith()); // clears the previous error
    try {
      await change();
    } on ApiException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
      return;
    }
    await _load(emit);
  }

  Future<void> _load(Emitter<CategoriesState> emit) async {
    try {
      final categories = await _repository.fetchCategories();
      emit(
        state.copyWith(
          status: CategoriesStatus.success,
          categories: categories,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: CategoriesStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}