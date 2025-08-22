
import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/domain/repositories/category_repository.dart';

class CreateCategory implements UseCase<CategoryEntity, CreateCategoryParams> {
  final CategoryRepository repository;

  CreateCategory(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
      CreateCategoryParams params) async {
    return await repository.createCategory(
      params.name,
      description: params.description,
      parentId: params.parentId,
      isActive: params.isActive,
      image: params.image,
    );
  }
}

class CreateCategoryParams {
  final String name;
  final String? description;
  final String? parentId;
  final bool isActive;
  final Map<String, dynamic>? image; 

  CreateCategoryParams({
    required this.name,
    this.description,
    this.parentId,
    this.isActive = true,
    this.image, 
  });
}
