import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sale.dart';
import 'package:stylish_admin/features/flash_sales/domain/repositories/flash_sale_repository.dart';

class GetFlashSales implements UseCase<List<FlashSale>, GetFlashSalesParams> {
  final FlashSaleRepository repository;

  const GetFlashSales(this.repository);
  @override
  Future<Either<Failure, List<FlashSale>>> call(
    GetFlashSalesParams params,
  ) async {
    return await repository.getFlashSales(status: params.status);
  }
}

class GetFlashSalesParams extends Equatable {
  final String? status;

  const GetFlashSalesParams({this.status});

  @override
  List<Object?> get props => [status];
}
