import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';

abstract class VariantRepository {
  Future<Either<Failure, bool>> manageProductVariants (String id, Map<String, dynamic> variantsData);

  Future<Either<Failure, ProductVariantEntity>> createProductVariant(String productId, ProductVariantEntity variant, {dynamic variantImage});

  Future<Either<Failure, ProductVariantEntity>> updateProductVariant(String variantId, ProductVariantEntity variant, {dynamic variantImage});

  Future<Either<Failure, bool>> deleteProductVariant(String productId, String variantId);

  Future<Either<Failure, List<ProductVariantEntity>>> getProductVariants(String productId);

  Future<Either<Failure, bool>> distributeProductStock(String productId, Map<String, dynamic> variantsData);
}