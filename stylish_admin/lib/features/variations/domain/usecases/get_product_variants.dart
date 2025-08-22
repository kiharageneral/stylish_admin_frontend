import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';
import 'package:stylish_admin/features/variations/domain/repositories/variant_repository.dart';

class GetProductVariants implements UseCase<List<ProductVariantEntity>, String> {
  final VariantRepository repository;

  GetProductVariants(this.repository);
  @override
  Future<Either<Failure, List<ProductVariantEntity>>> call(String productId) async{
 return await repository.getProductVariants(productId);
  }
}