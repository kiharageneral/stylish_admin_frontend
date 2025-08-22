
import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/exceptions.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/network/network_info.dart';
import 'package:stylish_admin/features/category/data/datasources/categories_remote_datasource.dart';
import 'package:stylish_admin/features/category/data/models/category_model.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/domain/entities/paginated_response.dart';
import 'package:stylish_admin/features/category/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedResponseEntity<CategoryEntity>>>
      getCategories({int page = 1, int pageSize = 20}) async {
    if (await networkInfo.isConnected) {
      try {
        final paginatedResponse = await remoteDataSource.getCategories(
          page: page,
          pageSize: pageSize,
        );

        final processedCategories = _addParentNames(paginatedResponse.results);

        return Right(PaginatedResponseEntity<CategoryEntity>(
          count: paginatedResponse.count,
          next: paginatedResponse.next,
          previous: paginatedResponse.previous,
          results: processedCategories,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(
            message: "Failed to get categories: ${e.toString()}"));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  List<CategoryEntity> _addParentNames(List<CategoryModel> categories) {
    final categoryMap = {for (var c in categories) c.id: c};

    return categories.map((category) {
      if (category.parentName != null && category.parentName!.isNotEmpty) {
        return category;
      }

      String? parentName;
      if (category.parent != null &&
          category.parent!.isNotEmpty &&
          categoryMap.containsKey(category.parent)) {
        parentName = categoryMap[category.parent]!.name;
      }

      return CategoryModel(
        id: category.id,
        name: category.name,
        description: category.description,
        image: category.image,
        isActive: category.isActive,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
        parent: category.parent,
        parentName: parentName,
        slug: category.slug,
      );
    }).toList();
  }

  @override
  Future<Either<Failure, CategoryEntity>> createCategory(
    String name, {
    String? description,
    String? parentId,
    bool isActive = true,
    Map<String, dynamic>? image,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final category = await remoteDataSource.createCategory(
          name,
          description: description,
          parent: parentId,
          isActive: isActive,
          image: image,
        );
        return Right(category);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCategory(id);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory(
    String id, {
    String? name,
    String? description,
    String? parentId,
    bool? isActive,
    Map<String, dynamic>? image,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final category = await remoteDataSource.updateCategory(
          id,
          name: name,
          description: description,
          parentId: parentId,
          isActive: isActive,
          image: image,
        );
        return Right(category);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }
}
