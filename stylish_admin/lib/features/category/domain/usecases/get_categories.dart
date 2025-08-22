
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/domain/entities/paginated_response.dart';
import 'package:stylish_admin/features/category/domain/repositories/category_repository.dart';

class GetCategoriesParams extends Equatable {
  final int page;
  final int pageSize;
  
  const GetCategoriesParams({
    this.page = 1,
    this.pageSize = 20,
  });
  
  @override
  List<Object> get props => [page, pageSize];
}

class GetCategories {
  final CategoryRepository repository;

  GetCategories(this.repository);

  Future<Either<Failure, PaginatedResponseEntity<CategoryEntity>>> call([GetCategoriesParams params = const GetCategoriesParams()]) async {
    return await repository.getCategories(
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}