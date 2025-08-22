import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/entities/product_image_entity.dart';
import 'package:stylish_admin/features/products/domain/repositories/product_repository.dart';

class ManagProductImages
    implements UseCase<List<ProductImageEntity>, ManageImagesParams> {
  final ProductRepository repository;

  ManagProductImages(this.repository);

  @override
  Future<Either<Failure, List<ProductImageEntity>>> call(
    ManageImagesParams params,
  ) async {
    return await repository.manageProductImages(
      params.id,
      params.images,
      params.isPrimaryList,
    );
  }
}

class ManageImagesParams {
  final String id;
  final List<dynamic> images;
  final List<bool> isPrimaryList;

  ManageImagesParams({
    required this.id,
    required this.images,
    required this.isPrimaryList,
  });
}
