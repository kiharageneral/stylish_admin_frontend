import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sale.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sales_stats.dart';

abstract class FlashSaleRepository {
  Future<Either<Failure, List<FlashSale>>> getFlashSales({String? status});
  Future<Either<Failure, FlashSale>> getFlashSaleById(String id);
  Future<Either<Failure, FlashSale>> createFlashSale(
    FlashSale flashSale, {
    List<Map<String, dynamic>>? products,
    dynamic imageFile,
  });
  Future<Either<Failure, FlashSale>> updateFlashSale(
    FlashSale flashSale,
    String id, {
    List<Map<String, dynamic>>? products,
    dynamic imageFile,
  });

  Future<Either<Failure, bool>> deleteFlashSale(String id);
  Future<Either<Failure, bool>> toggleFlashSaleStatus(String id);
  Future<Either<Failure, bool>> addProductsToFlashSale(
    String id,
    List<Map<String, dynamic>> productIds,
  );
  Future<Either<Failure, bool>> removeProductsFromFlashSale(
    String id,
    List<String> productIds,
  );
  Future<Either<Failure, bool>> updateFlashSaleItem(
    String flashSaleId,
    String itemId, {
    int? ovrrideDiscount,
    int? stockLimit,
  });
  Future<Either<Failure, FlashSaleStats>> getFlashSaleStats();
  Future<Either<Failure, FlashSaleStats>> getFlashSaleDetailStats(String id);
  Future<Either<Failure, List<Map<String, dynamic>>>> searchProducts(
    String query, {
    bool excludeActive = false,
  });
}
