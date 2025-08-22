import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class UpdateProductProfitMargin
    implements UseCase<ProductEntity, UpdateProfitMarginParams> {
  final ProductRepository repository;

  UpdateProductProfitMargin(this.repository);
  @override
  Future<Either<Failure, ProductEntity>> call(
    UpdateProfitMarginParams params,
  ) async {
    return await repository.updateProductProfitMargin(
      params.id,
      cost: params.cost,
      price: params.price,
      profitMargin: params.profitMargin,
      discountPrice: params.discountPrice,
    );
  }
}

class UpdateProfitMarginParams {
  final String id;
  final double cost;
  final double price;
  final double? discountPrice;
  final double profitMargin;

  UpdateProfitMarginParams({
    required this.id,
    required this.cost,
    required this.price,
    this.discountPrice,
    required this.profitMargin,
  });
}
