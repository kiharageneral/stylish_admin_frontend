import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sales_stats.dart';
import 'package:stylish_admin/features/flash_sales/domain/repositories/flash_sale_repository.dart';

class GetFlashSaleStats implements UseCase<FlashSaleStats, NoParams> {
  final FlashSaleRepository repository;

  const GetFlashSaleStats(this.repository);
  @override
  Future<Either<Failure, FlashSaleStats>> call(NoParams params) async {
    return await repository.getFlashSaleStats();
  }
}
