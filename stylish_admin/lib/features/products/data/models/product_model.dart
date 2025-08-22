import 'package:flutter/foundation.dart';
import 'package:stylish_admin/features/products/data/models/money_model.dart';
import 'package:stylish_admin/features/products/data/models/product_image_model.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/variations/data/models/product_variant_model.dart';
import 'package:stylish_admin/features/variations/data/models/product_variation_model.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.price,
    super.discountPrice,
    super.cost,
    super.stock,
    super.initialStock,
    required super.images,
    super.primaryImage,
    super.primaryImageUrl,
    super.variants,
    super.variations,
    super.createdAt,
    super.updatedAt,
    required super.rating,
    required super.stockStatus,
    required super.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      final categoryId = json['category']?.toString();
      final categoryName = json['category_name'] as String?;
      if (categoryId == null || categoryName == null) {
        throw FormatException('Missing or invalid category information', json);
      }

      final imagesList = json['images'] as List? ?? [];
      final primaryImageUrl = json['primary_image_url'] as String?;

      final List<ProductImageModel> images = imagesList
          .map((img) => ProductImageModel.fromJson(img as Map<String, dynamic>))
          .toList();

      ProductImageModel? primaryImage;

      if (images.isNotEmpty) {
        primaryImage = images.firstWhere(
          (img) => img.isPrimary,
          orElse: () => images.first,
        );
      }

      final variationsMap = json['variations'] as Map<String, dynamic>? ?? {};

      return ProductModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unnamed Product',
        description: json['description'] as String? ?? '',
        category: CategoryModel(id: categoryId, name: categoryName),
        price: MoneyModel(value: _parseDouble(json['price'])),
        discountPrice: json['discount_price'] != null
            ? MoneyModel(value: _parseDouble(json['discount_price']))
            : null,
        cost: json['cost'] != null
            ? MoneyModel(value: _parseDouble(json['cost']))
            : null,
        stock: _parseInt(json['current_stock'] ?? json['stock']),
        initialStock: _parseInt(json['initial_stock']),
        images: images,
        primaryImage: primaryImage,
        primaryImageUrl: primaryImage?.imageUrl ?? primaryImageUrl,
        variations: variationsMap.entries.map((entry) {
          return ProductVariationModel(
            id: entry.key,
            name: entry.key,
            values: List<String>.from(entry.value),
          );
        }).toList(),
        variants: (json['variants'] as List? ?? [])
            .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
            .toList(),
        rating: RatingModel(
          value: _parseDouble(json['rating']),
          count: _parseInt(json['reviews_count']),
        ),
        stockStatus: StockStatusExtension.fromString(
          json['stock_status'] as String? ?? 'outofstock',
        ),
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error parsing product: $e');
        print('JSON data: $json');
        print('Stack trace: $stackTrace');
      }

      throw FormatException('Failed to parse Product: ${e.toString()}', json);
    }
  }

  // Helper methods for safer parsiong to reducce verbosity
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  ProductEntity toDomain() {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      category: category,
      price: price,
      discountPrice: discountPrice,
      cost: cost,
      stock: stock,
      initialStock: initialStock,
      images: images,
      primaryImage: primaryImage,
      primaryImageUrl: primaryImageUrl,
      variations: variations,
      variants: variants,
      rating: rating,
      stockStatus: stockStatus,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'name': name,
      'description': description,
      'category': category.id,
      'price': price.value,
      'cost': cost?.value,
      'discount_price': discountPrice?.value,
      'is_active': isActive,
      'initial_stock': initialStock ?? stock,
      'variants': variants
          .map((v) => (v as ProductVariantModel).toJson())
          .toList(),
      'variations': variations
          .map((v) => (v as ProductVariationModel).toJson())
          .toList(),
    }..removeWhere((key, value) => value == null);
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.id,
      'price': price.value,
      'cost': cost?.value,
      'discount_price': discountPrice?.value,
      'is_active': isActive,
    }..removeWhere((key, value) => value == null);
  }
}

class CategoryModel extends ProductCategory {
  const CategoryModel({required super.id, required super.name});
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  ProductCategory toDomain() => ProductCategory(id: id, name: name);
}

class RatingModel extends Rating {
  const RatingModel({required super.value, required super.count});

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      value: ProductModel._parseDouble(json['value']),
      count: ProductModel._parseInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() => {'value': value, 'count': count};
}
