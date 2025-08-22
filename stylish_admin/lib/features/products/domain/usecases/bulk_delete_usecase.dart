import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class BulkDeleteUsecase implements UseCase<bool, List<String>> {
  final ProductRepository repository;

  BulkDeleteUsecase(this.repository);

  @override
  Future<Either<Failure, bool>> call(List<String> productIds) async {
    return await repository.bulkDeleteProducts(productIds);
  }
}
