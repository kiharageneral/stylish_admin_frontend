import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sale.dart';
import 'package:stylish_admin/features/flash_sales/domain/repositories/flash_sale_repository.dart';

class CreateFlashSale implements UseCase<FlashSale, CreateFlashSaleParams> {
  final FlashSaleRepository repository;

  CreateFlashSale(this.repository);
  @override
  Future<Either<Failure, FlashSale>> call(CreateFlashSaleParams params) async {
    return await repository.createFlashSale(
      params.flashSale,
      products: params.products,
      imageFile: params.imageFile,
    );
  }
}

class CreateFlashSaleParams extends Equatable {
  final FlashSale flashSale;
  final List<Map<String, dynamic>>? products;
  final dynamic imageFile;

  const CreateFlashSaleParams({
    required this.flashSale,
    required this.products,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [flashSale, products, imageFile];
}
