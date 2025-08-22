import 'package:equatable/equatable.dart';
import 'package:stylish_admin/features/products/domain/entities/money_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/product_image_entity.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variations_entity.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final ProductCategory category;
  final MoneyEntity price;
  final MoneyEntity? discountPrice;
  final MoneyEntity? cost;
  final int stock;
  final int? initialStock;
  final List<ProductImageEntity> images;
  final ProductImageEntity? primaryImage;
  final String? primaryImageUrl;
  final List<ProductVariationsEntity> variations;
  final List<ProductVariantEntity> variants;
  final Rating rating;
  final StockStatus stockStatus;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.discountPrice,
    this.stock = 0,
    this.initialStock,
    required this.images,
    this.primaryImage,
    this.primaryImageUrl,
    this.variations = const [],
    this.variants = const [],
    this.rating = const Rating(value: 0.0, count: 0),
    required this.stockStatus,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.cost,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    category,
    price,
    discountPrice,
    stock,
    initialStock,
    images,
    primaryImage,
    primaryImageUrl,
    variations,
    variants,
    rating,
    stockStatus,
    isActive,
    createdAt,
    updatedAt,
    cost,
  ];

  MoneyEntity get displayPrice => discountPrice ?? price;
  bool get isOnSale =>
      discountPrice != null && discountPrice!.value < price.value;
  bool get isLowStock => stock > 0 && stock < 10;

  bool get isOutOfStock => stock < 0;

  double? get profitMargin {
    if (cost != null && cost!.value > 0) {
      final effectivePrice = displayPrice.value;
      return ((effectivePrice - cost!.value) / price.value) * 100;
    }
    return null;
  }

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    ProductCategory? category,
    MoneyEntity? price,
    MoneyEntity? discountPrice,
    int? stock,
    int? initialStock,
    List<ProductImageEntity>? images,
    ProductImageEntity? primaryImage,
    String? primaryImageUrl,
    List<ProductVariationsEntity>? variations,
    List<ProductVariantEntity>? variants,
    Rating? rating,
    StockStatus? stockStatus,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    MoneyEntity? cost,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      initialStock: initialStock ?? this.initialStock,
      images: images ?? this.images,
      primaryImage: primaryImage ?? this.primaryImage,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      variations: variations ?? this.variations,
      variants: variants ?? this.variants,
      rating: rating ?? this.rating,
      stockStatus: stockStatus ?? this.stockStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProductCategory extends Equatable {
  final String id;
  final String name;

  const ProductCategory({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
  ProductCategory copyWith({String? id, String? name}) {
    return ProductCategory(id: id ?? this.id, name: name ?? this.name);
  }
}

class Rating extends Equatable {
  final double value;
  final int count;

  const Rating({required this.value, required this.count});
  @override
  List<Object?> get props => [value, count];

  Rating copyWith({double? value, int? count}) {
    return Rating(value: value ?? this.value, count: count ?? this.count);
  }
}

enum StockStatus { inStock, lowStock, outOfStock }

extension StockStatusX on StockStatus {
  String get displayName {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }
}

extension StockStatusExtension on StockStatus {
  static StockStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'in_stock':
      case 'instock':
        return StockStatus.inStock;
      case 'low_stock':
      case 'lowstock':
        return StockStatus.lowStock;
      case 'out_of_stock':
      case 'outofstock':
        return StockStatus.outOfStock;
      default:
        return StockStatus.inStock;
    }
  }
}
