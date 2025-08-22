import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class UpdateProductPrice implements UseCase<bool, UpdatePriceParams> {
  final ProductRepository repository;

  UpdateProductPrice(this.repository);
  @override
  Future<Either<Failure, bool>> call(UpdatePriceParams params) async {
    return await repository.updateProductPrice(
      params.id,
      price: params.price,
      discountPrice: params.discountPrice,
    );
  }
}

class UpdatePriceParams {
  final String id;
  final double price;
  final double? discountPrice;

  UpdatePriceParams({
    required this.id,
    required this.price,
    this.discountPrice,
  });
}
