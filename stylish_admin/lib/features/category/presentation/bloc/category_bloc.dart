
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/domain/usecases/create_categories.dart';
import 'package:stylish_admin/features/category/domain/usecases/delete_categories.dart';
import 'package:stylish_admin/features/category/domain/usecases/get_categories.dart';
import 'package:stylish_admin/features/category/domain/usecases/update_categories.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategories getCategories;
  final CreateCategory createCategory;
  final DeleteCategory deleteCategory;
  final UpdateCategory updateCategory;

  // Pagination state
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMorePages = true;

  CategoryBloc({
    required this.getCategories,
    required this.createCategory,
    required this.deleteCategory,
    required this.updateCategory,
  }) : super(CategoryInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<LoadMoreCategoriesEvent>(_onLoadMoreCategories);
    on<CreateCategoryEvent>(_onCreateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<ValidateCategoryNameEvent>(_onValidateCategoryName);
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading());

    _currentPage = 1;
    _hasMorePages = true;

    final result = await getCategories(
        GetCategoriesParams(page: _currentPage, pageSize: _pageSize));

    result.fold(
      (failure) => emit(CategoriesError(failure.toString())),
      (paginatedResponse) {
        _hasMorePages = paginatedResponse.hasNextPage;

        emit(CategoriesLoaded(
          categories: paginatedResponse.results,
          hasMorePages: _hasMorePages,
          currentPage: _currentPage,
          totalCount: paginatedResponse.count,
        ));
      },
    );
  }

  Future<void> _onLoadMoreCategories(
    LoadMoreCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoaded && _hasMorePages) {
      emit(CategoriesLoadingMore(
        categories: currentState.categories,
        currentPage: _currentPage,
        hasMorePages: _hasMorePages,
        totalCount: currentState.totalCount,
      ));

      // Load next page
      _currentPage++;

      try {
        final result = await getCategories(
            GetCategoriesParams(page: _currentPage, pageSize: _pageSize));

        result.fold(
          (failure) {
            _currentPage--;
            emit(CategoriesError(failure.toString()));
            emit(currentState.copyWith(hasMorePages: false));
          },
          (paginatedResponse) {
            if (paginatedResponse.results.isEmpty ||
                !paginatedResponse.hasNextPage) {
              _hasMorePages = false;
              emit(CategoriesLoaded(
                categories: currentState.categories,
                hasMorePages: false,
                currentPage: _currentPage - 1, 
                totalCount: currentState.totalCount,
              ));
              return;
            }

            _hasMorePages = paginatedResponse.hasNextPage;

            final updatedCategories = [
              ...currentState.categories,
              ...paginatedResponse.results,
            ];

            emit(CategoriesLoaded(
              categories: updatedCategories,
              hasMorePages: _hasMorePages,
              currentPage: _currentPage,
              totalCount: paginatedResponse.count,
            ));
          },
        );
      } catch (e) {
        _currentPage--;
        emit(
            CategoriesError("Error fetching more categories: ${e.toString()}"));
        emit(currentState.copyWith(hasMorePages: false));
      }
    }
  }

  Future<void> _onCreateCategory(
    CreateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final currentState = state;

    if (currentState is CategoriesLoaded) {
      final nameExists = currentState.categories
          .where((category) => (event.parentId == category.parent))
          .any((category) =>
              category.name.toLowerCase() == event.name.toLowerCase());

      if (nameExists) {
        emit(CategoryNameError(
            'A category with this name already exists in this location.'));
        emit(currentState);
        return;
      }
    }

    emit(CategoriesLoading());

    try {
      // print('Creating category: ${event.name}, parent: ${event.parentId}');

      final result = await createCategory(
        CreateCategoryParams(
          name: event.name,
          description: event.description,
          parentId: event.parentId,
          isActive: event.isActive,
          image: event.image,
        ),
      );

      result.fold(
        (failure) {
          // print('Create category failure: ${failure.toString()}');

          if (failure.toString().contains('already exists')) {
            emit(CategoryNameError(
                'A category with this name already exists in this location.'));
          } else {
            emit(CategoriesError(failure.toString()));
          }

          if (currentState is CategoriesLoaded) {
            emit(currentState);
          }
        },
        (category) {
          // print('Category created successfully: ${category.id}');

          emit(CategoryCreated(category));

          if (currentState is CategoriesLoaded) {
            emit(CategoriesLoaded(
              categories: [category, ...currentState.categories],
              hasMorePages: currentState.hasMorePages,
              currentPage: currentState.currentPage,
              totalCount: currentState.totalCount + 1,
            ));
          } else {
            add(LoadCategoriesEvent());
          }
        },
      );
    } catch (e) {
      print('Unexpected error creating category: $e');
      emit(CategoriesError(e.toString()));
      if (currentState is CategoriesLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoaded) {
      final originalCategories = currentState.categories;

      final nameExists = currentState.categories
          .where((category) =>
              category.id != event.id &&
              (category.parent == event.parentId ||
                  (category.parent == null && event.parentId == null)))
          .any((category) =>
              category.name.toLowerCase() == event.name.toLowerCase());

      if (nameExists) {
        emit(CategoryNameError(
            'A category with this name already exists in this location.'));
        emit(currentState);
        return;
      }

      emit(CategoriesLoading());

      final result = await updateCategory(
        UpdateCategoryParams(
          id: event.id,
          name: event.name,
          description: event.description,
          parentId: event.parentId,
          isActive: event.isActive,
          image: event.image,
        ),
      );

      result.fold(
        (failure) {
          if (failure.toString().contains('already exists')) {
            emit(CategoryNameError(
                'A category with this name already exists in this location.'));
          } else {
            emit(CategoriesError(failure.toString()));
          }
          emit(CategoriesLoaded(
            categories: originalCategories,
            hasMorePages: currentState.hasMorePages,
            currentPage: currentState.currentPage,
            totalCount: currentState.totalCount,
          ));
        },
        (updatedCategory) {
          final updatedCategories = originalCategories.map((category) {
            return category.id == updatedCategory.id
                ? updatedCategory
                : category;
          }).toList();

          emit(CategoryUpdated(updatedCategory));

          emit(CategoriesLoaded(
            categories: updatedCategories,
            hasMorePages: currentState.hasMorePages,
            currentPage: currentState.currentPage,
            totalCount: currentState.totalCount,
          ));
        },
      );
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoriesLoaded) {
      final updatedCategories =
          currentState.categories.where((c) => c.id != event.id).toList();

      emit(CategoriesLoaded(
        categories: updatedCategories,
        hasMorePages: currentState.hasMorePages,
        currentPage: currentState.currentPage,
        totalCount: currentState.totalCount - 1,
      ));

      final result = await deleteCategory(event.id);
      result.fold(
        (failure) {
          emit(CategoriesError(failure.toString()));
          // Restore the original list if deletion failed
          emit(currentState);
        },
        (_) {
        },
      );
    }
  }

  void _onValidateCategoryName(
    ValidateCategoryNameEvent event,
    Emitter<CategoryState> emit,
  ) {
    final currentState = state;
    if (currentState is CategoriesLoaded) {
      bool nameExists;

      if (event.excludeCategoryId != null) {
        nameExists = currentState.categories
            .where((category) => category.id != event.excludeCategoryId)
            .any((category) =>
                category.name.toLowerCase() == event.name.toLowerCase());
      } else {
        nameExists = currentState.categories.any((category) =>
            category.name.toLowerCase() == event.name.toLowerCase());
      }

      if (nameExists) {
        emit(CategoryNameError('A category with this name already exists.'));
        emit(currentState);
      } else {
        emit(CategoryNameValid());
        emit(currentState);
      }
    }
  }
}
