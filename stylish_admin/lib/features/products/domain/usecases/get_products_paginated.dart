import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/entities/paginated_products_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class GetProductsPaginated
    implements UseCase<PaginatedProductsEntity, ProductsFilterParams> {
  final ProductRepository repository;

  GetProductsPaginated(this.repository);

  @override
  Future<Either<Failure, PaginatedProductsEntity>> call(
    ProductsFilterParams params,
  ) async {
    return await repository.getProductsPaginated(
      page: params.page,
      pageSize: params.pageSize,
      search: params.search,
      status: params.status,
      stockStatus: params.stockStatus,
      categoryId: params.categoryId,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      extraParams: params.extraParams,
    );
  }
}

class ProductsFilterParams {
  final int page;
  final int pageSize;
  final String? search;
  final String? status;
  final StockStatus? stockStatus;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final Map<String, dynamic>? extraParams;

  ProductsFilterParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.status,
    this.stockStatus,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.extraParams,
  });
}
