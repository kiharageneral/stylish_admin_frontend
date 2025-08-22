import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class GetProductByIdUsecase implements UseCase<ProductEntity, String> {
  final ProductRepository repository;

  GetProductByIdUsecase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(String id) async{
return await repository.getProductById(id);
  }
}