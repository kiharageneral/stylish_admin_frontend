import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class GetProductCategoriesUsecase implements UseCase<List<ProductCategory>, NoParams> {
  final ProductRepository repository;

  GetProductCategoriesUsecase(this.repository);
  @override
  Future<Either<Failure, List<ProductCategory>>> call(NoParams params) async{
return await repository.getProductCategories(); 
  }
}