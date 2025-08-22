import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/flash_sales/domain/repositories/flash_sale_repository.dart';

class RemoveProductsFromFlashSale
    implements UseCase<bool, RemoveProductsParams> {
  final FlashSaleRepository repository;

  const RemoveProductsFromFlashSale(this.repository);
  @override
  Future<Either<Failure, bool>> call(RemoveProductsParams params) async {
    return await repository.removeProductsFromFlashSale(
      params.flashSaleId,
      params.productIds,
    );
  }
}

class RemoveProductsParams {
  final String flashSaleId;
  final List<String> productIds;

  const RemoveProductsParams({
    required this.flashSaleId,
    required this.productIds,
  });
}
