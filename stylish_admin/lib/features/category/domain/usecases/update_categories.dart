
import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/domain/repositories/category_repository.dart';

class UpdateCategoryParams {
  final String id;
  final String? name;
  final String? description;
  final String? parentId;
  final bool? isActive;
  final Map<String, dynamic>? image; 

  UpdateCategoryParams({
    required this.id,
    this.name,
    this.description,
    this.isActive,
    this.parentId,
    this.image,
  });
}

class UpdateCategory implements UseCase<CategoryEntity, UpdateCategoryParams> {
  final CategoryRepository repository;

  UpdateCategory(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
      UpdateCategoryParams params) async {
    return await repository.updateCategory(
      params.id,
      name: params.name,
      description: params.description,
      isActive: params.isActive,
      parentId: params.parentId,
      image: params.image,
    );
  }
}
