import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/variations/domain/repositories/variant_repository.dart';

class DistributeProductStockUseCase
    implements UseCase<bool, DistributeStockParams> {
  final VariantRepository repository;

  DistributeProductStockUseCase(this.repository);
  @override
  Future<Either<Failure, bool>> call(DistributeStockParams params) async {
    return await repository.distributeProductStock(
      params.productId,
      params.variantData,
    );
  }
}

class DistributeStockParams {
  final String productId;
  final Map<String, dynamic> variantData;

  DistributeStockParams({required this.productId, required this.variantData});
}
