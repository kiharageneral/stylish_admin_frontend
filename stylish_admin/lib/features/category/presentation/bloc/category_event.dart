part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategoriesEvent extends CategoryEvent {}

class LoadMoreCategoriesEvent extends CategoryEvent {}

class CreateCategoryEvent extends CategoryEvent {
  final String name;
  final String description;
  final String? parentId;
  final bool isActive;
  final Map<String, dynamic>? image;

  const CreateCategoryEvent({
    required this.name,
    required this.description,
    this.parentId,
    required this.isActive,
    this.image,
  });

  @override
  List<Object?> get props => [name, description, parentId, isActive, image];
}

class DeleteCategoryEvent extends CategoryEvent {
  final String id;

  const DeleteCategoryEvent(this.id);

  @override
  List<Object> get props => [id];
}

class UpdateCategoryEvent extends CategoryEvent {
  final String id;
  final String name;
  final String description;
  final String? parentId;
  final bool isActive;
  final Map<String, dynamic>? image;

  const UpdateCategoryEvent({
    required this.id,
    required this.name,
    required this.description,
    this.parentId,
    required this.isActive,
    this.image,
  });

  @override
  List<Object?> get props => [id, name, description, parentId, isActive, image];
}

class ValidateCategoryNameEvent extends CategoryEvent {
  final String name;
  final String? excludeCategoryId;

  const ValidateCategoryNameEvent({
    required this.name,
    this.excludeCategoryId,
  });

  @override
  List<Object?> get props => [name, excludeCategoryId];
}