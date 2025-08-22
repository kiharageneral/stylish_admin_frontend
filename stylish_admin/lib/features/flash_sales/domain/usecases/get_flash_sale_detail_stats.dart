import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sales_stats.dart';
import 'package:stylish_admin/features/flash_sales/domain/repositories/flash_sale_repository.dart';

class GetFlashSaleDetailStats implements UseCase<FlashSaleStats, String> {
  final FlashSaleRepository repository;

  const GetFlashSaleDetailStats(this.repository);
  @override
  Future<Either<Failure, FlashSaleStats>> call(String id) async {
    return await repository.getFlashSaleDetailStats(id);
  }
}
