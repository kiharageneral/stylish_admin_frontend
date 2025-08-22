import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class UpdateProductUsecase
    implements UseCase<ProductEntity, UpdateProductParams> {
  final ProductRepository repository;

  UpdateProductUsecase(this.repository);
  @override
  Future<Either<Failure, ProductEntity>> call(
    UpdateProductParams params,
  ) async {
    return await repository.updateProduct(
      params.id,
      params.product,
      newImages: params.newImages,
    );
  }
}

class UpdateProductParams {
  final String id;
  final ProductEntity product;
  final List<dynamic>? newImages;

  UpdateProductParams({
    required this.id,
    required this.product,
    this.newImages,
  });
}
