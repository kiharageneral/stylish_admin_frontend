import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class DeleteProductImageUsecase implements UseCase<bool, DeleteImageParams> {
  final ProductRepository repository;

  DeleteProductImageUsecase(this.repository);
  @override
  Future<Either<Failure, bool>> call(DeleteImageParams params) async{
   return await repository.deleteProductImage(params.productId, params.imageId);
  }
}

class DeleteImageParams {
  final String productId;
  final String imageId;

  DeleteImageParams({required this.productId, required this.imageId});
  
}