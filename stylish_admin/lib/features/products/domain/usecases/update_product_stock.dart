import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class UpdateProductStock implements UseCase<bool, UpdateStockParams> {
  final ProductRepository repository;

  UpdateProductStock(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateStockParams params) async {
    return await repository.updateProductStock(
      params.id,
      params.newStock,
      params.reason,
    );
  }
}

class UpdateStockParams {
  final String id;
  final int newStock;
  final String reason;

  UpdateStockParams({
    required this.id,
    required this.newStock,
    required this.reason,
  });
}
