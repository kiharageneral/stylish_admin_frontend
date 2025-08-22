import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/variations/domain/repositories/variant_repository.dart';

class DeleteProductVariant implements UseCase<bool, DeleteVariantParams> {
  final VariantRepository repository;

  DeleteProductVariant(this.repository);
  @override
  Future<Either<Failure, bool>> call(DeleteVariantParams params) async {
    return await repository.deleteProductVariant(
      params.productId,
      params.variantId,
    );
  }
}

class DeleteVariantParams {
  final String productId;
  final String variantId;

  DeleteVariantParams({required this.productId, required this.variantId});
}
