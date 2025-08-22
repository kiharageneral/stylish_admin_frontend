part of 'category_bloc.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoriesLoading extends CategoryState {}

class CategoriesLoaded extends CategoryState {
  final List<CategoryEntity> categories;
  final bool hasMorePages;
  final int currentPage;
  final int totalCount;
  
  const CategoriesLoaded({
    required this.categories,
    this.hasMorePages = false,
    this.currentPage = 1,
    this.totalCount = 0,
  });

  @override
  List<Object> get props => [categories, hasMorePages, currentPage, totalCount];
}

class CategoriesLoadingMore extends CategoriesLoaded {
  const CategoriesLoadingMore({
    required super.categories,
    required super.hasMorePages,
    required super.currentPage,
    required super.totalCount,
  });
  
  @override
  List<Object> get props => [categories, hasMorePages, currentPage, totalCount, 'loading_more'];
}

class CategoriesError extends CategoryState {
  final String message;
  const CategoriesError(this.message);

  @override
  List<Object> get props => [message];
}

class CategoryCreated extends CategoryState {
  final CategoryEntity category;
  const CategoryCreated(this.category);

  @override
  List<Object> get props => [category];
}

class CategoryUpdated extends CategoryState {
  final CategoryEntity category;

  const CategoryUpdated(this.category);

  @override
  List<Object> get props => [category];
}

class CategoryNameError extends CategoryState {
  final String message;
  const CategoryNameError(this.message);

  @override
  List<Object> get props => [message];
}

class CategoryNameValid extends CategoryState {}

extension CategoriesLoadedExtension on CategoriesLoaded {
  CategoriesLoaded copyWith({
    List<CategoryEntity>? categories,
    bool? hasMorePages,
    int? currentPage,
    int? totalCount,
  }) {
    return CategoriesLoaded(
      categories: categories ?? this.categories,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}