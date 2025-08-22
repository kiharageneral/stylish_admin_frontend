import 'package:equatable/equatable.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';

class ProductFiltersEntity extends Equatable {
  final List<ProductCategory> categories;
  final List<String> statusOptions;
  final List<StockStatus> stockStatusOptions;
  final double? minPrice;
  final double? maxPrice;

  const ProductFiltersEntity({
    required this.categories,
    required this.statusOptions,
    required this.stockStatusOptions,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [
    categories,
    statusOptions,
    stockStatusOptions,
    minPrice,
    maxPrice,
  ];

  ProductFiltersEntity copyWith({
    List<ProductCategory>? categories,
    List<String>? statusOptions,
    List<StockStatus>? stockStatusOptions,
    double? minPrice,
    double? maxPrice,
  }) {
    return ProductFiltersEntity(
      categories: categories ?? this.categories,
      statusOptions: statusOptions ?? this.statusOptions,
      stockStatusOptions: stockStatusOptions ?? this.stockStatusOptions,
      minPrice: minPrice ?? this.maxPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}
