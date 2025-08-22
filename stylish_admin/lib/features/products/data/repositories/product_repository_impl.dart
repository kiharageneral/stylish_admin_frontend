import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/exceptions.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/network/network_info.dart';
import 'package:stylish_admin/features/products/data/datasources/product_remote_datasource.dart';
import 'package:stylish_admin/features/products/data/models/money_model.dart';
import 'package:stylish_admin/features/products/data/models/product_image_model.dart';
import 'package:stylish_admin/features/products/data/models/product_model.dart';
import 'package:stylish_admin/features/products/domain/entities/paginated_products_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/product_filters_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/product_image_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';
import 'package:stylish_admin/features/variations/data/models/product_variant_model.dart';
import 'package:stylish_admin/features/variations/data/models/product_variation_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource remoteDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  /// A private helper mehtod to execute a repository action, handling network checks and exceptions centrally.
  Future<Either<Failure, T>> _getRepositoryAction<T>(
    Future<T> Function() action,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await action();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException {
        return Left(NetworkFailure());
      } on CacheException {
        return Left(CacheFailure());
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> bulkDeleteProducts(
    List<String> productIds,
  ) async {
    return await _getRepositoryAction(
      () => remoteDataSource.bulkDeleteProducts(productIds),
    );
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct(
    ProductEntity product, {
    List? images,
  }) async {
    return _getRepositoryAction(
      () => remoteDataSource.createProduct(
        _mapProductToModel(product),
        images: images,
      ),
    );
  }

  ProductModel _mapProductToModel(ProductEntity product) {
    if (product is ProductModel) {
      return product;
    }

    return ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      category: product.category is CategoryModel
          ? product.category as CategoryModel
          : CategoryModel(id: product.category.id, name: product.category.name),
      price: product.price is MoneyModel
          ? product.price as MoneyModel
          : MoneyModel(
              value: product.price.value,
              currency: product.price.currency,
            ),
      cost: product.cost != null
          ? (product.cost is MoneyModel
                ? product.cost as MoneyModel
                : MoneyModel(
                    value: product.cost!.value,
                    currency: product.cost!.currency,
                  ))
          : null,
      discountPrice: product.discountPrice != null
          ? (product.discountPrice is MoneyModel
                ? product.discountPrice as MoneyModel
                : MoneyModel(
                    value: product.discountPrice!.value,
                    currency: product.discountPrice!.currency,
                  ))
          : null,
      stock: product.stock,
      images: product.images
          .map(
            (image) => image is ProductImageModel
                ? image
                : ProductImageModel(
                    id: image.id,
                    imageUrl: image.imageUrl,
                    altText: image.altText,
                    isPrimary: image.isPrimary,
                    productId: image.productId,
                  ),
          )
          .toList(),
      primaryImage: product.primaryImage != null
          ? (product.primaryImage is ProductImageModel
                ? product.primaryImage as ProductImageModel
                : ProductImageModel(
                    id: product.primaryImage!.id,
                    imageUrl: product.primaryImage!.imageUrl,
                    altText: product.primaryImage!.altText,
                    isPrimary: product.primaryImage!.isPrimary,
                    order: product.primaryImage!.order,
                    createdAt: product.primaryImage!.createdAt,
                    productId: product.primaryImage!.productId,
                  ))
          : null,
      variations: product.variations
          .map(
            (variation) => variation is ProductVariationModel
                ? variation
                : ProductVariationModel(
                    id: variation.id,
                    name: variation.name,
                    values: variation.values,
                  ),
          )
          .toList(),
      variants: product.variants
          .map(
            (variant) => variant is ProductVariantModel
                ? variant
                : ProductVariantModel(
                    id: variant.id,
                    productId: variant.productId,
                    attributes: variant.attributes,
                    sku: variant.sku,
                    price: variant.price is MoneyModel
                        ? variant.price as MoneyModel
                        : MoneyModel(
                            value: variant.price.value,
                            currency: variant.price.currency,
                          ),
                    discountPrice: variant.discountPrice != null
                        ? (variant.displayPrice is MoneyModel
                              ? variant.discountPrice as MoneyModel
                              : MoneyModel(
                                  value: variant.discountPrice!.value,
                                  currency: variant.discountPrice!.currency,
                                ))
                        : null,
                    stock: variant.stock,
                    image: variant.image != null
                        ? (variant.image is ProductImageModel
                              ? variant.image as ProductImageModel
                              : ProductImageModel(
                                  id: variant.image!.id,
                                  imageUrl: variant.image!.imageUrl,
                                  altText: variant.image!.altText,
                                  isPrimary: variant.image!.isPrimary,
                                  createdAt: variant.image!.createdAt,
                                  order: variant.image!.order,
                                  productId: variant.image!.productId,
                                ))
                        : null,
                    createdAt: variant.createdAt,
                    updatedAt: variant.updatedAt,
                  ),
          )
          .toList(),
      rating: product.rating is RatingModel
          ? product.rating as RatingModel
          : RatingModel(
              value: product.rating.value,
              count: product.rating.count,
            ),
      stockStatus: product.stockStatus,
      isActive: product.isActive,
      initialStock: product.initialStock,

      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  @override
  Future<Either<Failure, bool>> deleteProduct(String id) async {
    return await _getRepositoryAction(() => remoteDataSource.deleteProduct(id));
  }

  @override
  Future<Either<Failure, bool>> deleteProductImage(
    String productId,
    String imageId,
  ) async {
    return await _getRepositoryAction(
      () => remoteDataSource.deleteProductImage(productId, imageId),
    );
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    return await _getRepositoryAction(
      () => remoteDataSource.getProductById(id),
    );
  }

  @override
  Future<Either<Failure, List<ProductCategory>>> getProductCategories() async {
    return await _getRepositoryAction(
      () => remoteDataSource.getProductCategories(),
    );
  }

  @override
  Future<Either<Failure, ProductFiltersEntity>> getProductFilters() async {
    return await _getRepositoryAction(
      () => remoteDataSource.getProductFilters(),
    );
  }

  @override
  Future<Either<Failure, PaginatedProductsEntity>> getProductsPaginated({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    stockStatus,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    Map<String, dynamic>? extraParams,
  }) async {
    final params = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (stockStatus != null) 'stock_status': stockStatus.toString(),
      if (categoryId != null && categoryId.isNotEmpty)
        'category_id': categoryId,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };

    if (extraParams != null) {
      params.addAll(
        extraParams.map((key, value) => MapEntry(key, value.toString())),
      );
    }
    return await _getRepositoryAction(() async {
      final model = await remoteDataSource.getProductsPaginated(params);
      return model.toDomain();
    });
  }

  @override
  Future<Either<Failure, List<ProductImageEntity>>> manageProductImages(
    String id,
    List images,
    List<bool> isPrimaryList,
  ) async {
    return await _getRepositoryAction<List<ProductImageEntity>>(() async {
      final imageModels = await remoteDataSource.manageProductImages(
        id,
        images: images,
      );
      return imageModels.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<Either<Failure, bool>> toggleProductStatus(String id) async {
    return await _getRepositoryAction(
      () => remoteDataSource.toggleProductStatus(id),
    );
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
    String id,
    ProductEntity product, {
    List? newImages,
    List<String>? removedImagesIds,
  }) async {
    return await _getRepositoryAction(
      () => remoteDataSource.updateProduct(
        id,
        _mapProductToModel(product),
        newImages: newImages,
        removedImageIds: removedImagesIds,
      ),
    );
  }

  @override
  Future<Either<Failure, bool>> updateProductPrice(
    String id, {
    required double price,
    double? discountPrice,
  }) async {
    return await _getRepositoryAction(() async {
      await remoteDataSource.updateProductPrice(
        id,
        price: price,
        discountPrice: discountPrice,
      );
      return true;
    });
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProductProfitMargin(
    String id, {
    required double cost,
    required double price,
    double? discountPrice,
    required double profitMargin,
  }) async {
    return await _getRepositoryAction(
      () => remoteDataSource.updateProductProfitMargin(
        id,
        cost: cost,
        price: price,
        profitMargin: profitMargin,
      ),
    );
  }

  @override
  Future<Either<Failure, bool>> updateProductStock(
    String id,
    int newStock,
    String reason,
  ) async {
    return await _getRepositoryAction(
      () => remoteDataSource.updateProductStock(id, newStock, reason),
    );
  }
}
