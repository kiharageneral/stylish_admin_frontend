import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';
import 'package:stylish_admin/features/variations/domain/repositories/variant_repository.dart';

class CreateProductVariant
    implements UseCase<ProductVariantEntity, CreateVariantParams> {
  final VariantRepository repository;

  CreateProductVariant(this.repository);
  @override
  Future<Either<Failure, ProductVariantEntity>> call(
    CreateVariantParams params,
  ) async {
    return await repository.createProductVariant(
      params.productId,
      params.variant,
      variantImage: params.variantImage,
    );
  }
}

class CreateVariantParams {
  final String productId;
  final ProductVariantEntity variant;
  final dynamic variantImage;

  CreateVariantParams({
    required this.productId,
    required this.variant,
    this.variantImage,
  });
}
