import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/flash_sales/domain/repositories/flash_sale_repository.dart';

class DeleteFlashSale implements UseCase<bool, String> {
  final FlashSaleRepository repository;

  DeleteFlashSale(this.repository);

  @override
  Future<Either<Failure, bool>> call(String id) async {
    return await repository.deleteFlashSale(id);
  }
}
