import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/variations/domain/repositories/variant_repository.dart';

class ManageProductVariants implements UseCase<bool, ManageVariantsParams> {
  final VariantRepository repository;

  ManageProductVariants(this.repository);
  @override
  Future<Either<Failure, bool>> call(ManageVariantsParams params)  async {
    return await repository.manageProductVariants(params.id, params.variantsData);
  }
}

class ManageVariantsParams {
  final String id;
  final Map<String, dynamic> variantsData;

  ManageVariantsParams({required this.id, required this.variantsData});
}
