
import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/domain/entities/paginated_response.dart';

abstract class CategoryRepository {
  Future<Either<Failure, PaginatedResponseEntity<CategoryEntity>>> getCategories({int page = 1, int pageSize = 20});
  
  Future<Either<Failure, CategoryEntity>> createCategory(
    String name, {
    String? description, 
    String? parentId,
    bool isActive = true,
    Map<String, dynamic>? image,
  });
  
  Future<Either<Failure, void>> deleteCategory(String id);
  
  Future<Either<Failure, CategoryEntity>> updateCategory(
    String id, {
    String? name,
    String? description,
    String? parentId,
    bool? isActive,
    Map<String, dynamic>? image,
  });
}