import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/flash_sales/domain/repositories/flash_sale_repository.dart';

class AddProductsToFlashSale implements UseCase<bool, AddProductsParams> {
  final FlashSaleRepository repository;

  AddProductsToFlashSale(this.repository);
  @override
  Future<Either<Failure, bool>> call(AddProductsParams params) async {
    return await repository.addProductsToFlashSale(
      params.flashSaleId,
      params.products,
    );
  }
} 

class AddProductsParams extends Equatable {
  final String flashSaleId;
  final List<Map<String, dynamic>> products;

  const AddProductsParams({required this.flashSaleId, required this.products});

  @override
  List<Object?> get props => [flashSaleId, products];
}
