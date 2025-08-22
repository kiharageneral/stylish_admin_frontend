import 'package:stylish_admin/features/products/data/models/product_model.dart';
import 'package:stylish_admin/features/products/domain/entities/product_filters_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';

class ProductFilterModel extends ProductFiltersEntity {
  const ProductFilterModel({
    required super.categories,
    required super.statusOptions,
    required super.stockStatusOptions,
    super.maxPrice,
    super.minPrice,
  });

  factory ProductFilterModel.fromJson(Map<String, dynamic> json) {
    final stockStatusList = (List<String>.from(
      json['stock_status_options'] ?? [],
    )).map(_mapStringToStockStatus).toList();

    return ProductFilterModel(
      categories: (json['categories'] as List)
          .map((category) => CategoryModel.fromJson(category))
          .toList(),
      statusOptions: List<String>.from(json['status_options'] ?? []),
      stockStatusOptions: stockStatusList,
      minPrice: json['min_price']?.toDouble(),
      maxPrice: json['max_price']?.toDouble(),
    );
  }

  static StockStatus _mapStringToStockStatus(String status) {
    switch (status) {
      case 'in_stock':
        return StockStatus.inStock;
      case 'low_stock':
        return StockStatus.lowStock;
      case 'out_of_stock':
        return StockStatus.outOfStock;
      default:
        return StockStatus.inStock;
    }
  }
}
