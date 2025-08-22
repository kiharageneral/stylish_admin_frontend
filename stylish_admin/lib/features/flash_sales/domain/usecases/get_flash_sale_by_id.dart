import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sale.dart';
import 'package:stylish_admin/features/flash_sales/domain/repositories/flash_sale_repository.dart';

class GetFlashSaleById implements UseCase<FlashSale, String> {
  final FlashSaleRepository repository;

  const GetFlashSaleById(this.repository);
  @override
  Future<Either<Failure, FlashSale>> call(String id) async {
    return await repository.getFlashSaleById(id);
  }
}
