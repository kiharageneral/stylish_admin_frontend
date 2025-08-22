import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class DeleteProductUsecase implements UseCase<bool, String> {
  final ProductRepository repository;

  DeleteProductUsecase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String id) async{
return await repository.deleteProduct(id);
  }
}