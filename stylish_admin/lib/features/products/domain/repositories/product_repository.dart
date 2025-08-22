import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/features/products/domain/entities/paginated_products_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/product_filters_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/product_image_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, ProductEntity>> getProductById(String id);

  Future<Either<Failure, ProductEntity>> createProduct(
    ProductEntity product, {
    List<dynamic>? images,
  });

  Future<Either<Failure, ProductEntity>> updateProduct(
    String id,
    ProductEntity product, {
    List<dynamic>? newImages,
    List<String>? removedImagesIds,
  });

  Future<Either<Failure, bool>> deleteProduct(String id);

  Future<Either<Failure, bool>> updateProductStock(
    String id,
    int newStock,
    String reason,
  );

  Future<Either<Failure, bool>> updateProductPrice(
    String id, {
    required double price,
    double? discountPrice,
  });

  Future<Either<Failure, bool>> toggleProductStatus(String id);

  Future<Either<Failure, List<ProductImageEntity>>> manageProductImages(
    String id,
    List<dynamic> images,
    List<bool> isPrimaryList,
  );

  Future<Either<Failure, bool>> deleteProductImage(
    String productId,
    String imageId,
  );

  Future<Either<Failure, bool>> bulkDeleteProducts(List<String> productIds);

  Future<Either<Failure, List<ProductCategory>>> getProductCategories();

  Future<Either<Failure, ProductFiltersEntity>> getProductFilters();

  Future<Either<Failure, ProductEntity>> updateProductProfitMargin(
    String id, {
    required double cost,
    required double price,
    double? discountPrice,
    required double profitMargin,
  });

  Future<Either<Failure, PaginatedProductsEntity>> getProductsPaginated({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    dynamic stockStatus,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    Map<String, dynamic>? extraParams,
  });
}
