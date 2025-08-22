import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class CreateProductUsecase implements UseCase<ProductEntity, CreateProductParams> {
  final ProductRepository repository;

  CreateProductUsecase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(CreateProductParams params) async{
return await repository.createProduct(params.product, images: params.images);
  }

 
  
}

class CreateProductParams {
  final ProductEntity product;
  final List<dynamic>? images;

  CreateProductParams({required this.product,  this.images});
  
}