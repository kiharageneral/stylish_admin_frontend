import 'package:stylish_admin/features/products/data/models/money_model.dart';
import 'package:stylish_admin/features/products/data/models/product_image_model.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';

class ProductVariantModel extends ProductVariantEntity {
  const ProductVariantModel({
    required super.id,
    required super.productId,
    required super.attributes,
    super.sku,
    required super.price,
    super.discountPrice,
    required super.stock,
    super.image,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    // Process image data

    ProductImageModel? imageModel;

    if (json['imae'] != null && json['image'] is Map<String, dynamic>) {
      imageModel = ProductImageModel.fromJson(json['image']);
    } else if (json['image_url'] != null) {
      imageModel = ProductImageModel(
        id: '${json['id']}_image',
        productId: json['product']?.toString(),
        imageUrl: json['image_url'],
        altText: 'variant image ',
        isPrimary: false,
        order: 0,
        createdAt: DateTime.now(),
      );
    }

    return ProductVariantModel(
      id: json['id'].toString(),
      productId: json['product'].toString(),
      attributes: _parseAttributes(json['attributes']),
      sku: json['sku'],
      price: MoneyModel(value: _parseDouble(json['price'])),
      discountPrice: json['discount_price'] != null
          ? MoneyModel(value: _parseDouble(json['discount_price']))
          : null,
      stock: json['stock'] is String
          ? int.tryParse(json['stock']) ?? 0
          : json['stock'] ?? 0,
      image: imageModel,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  ProductVariantEntity toDomain() {
    return ProductVariantEntity(
      id: id,
      productId: productId,
      attributes: attributes,
      sku: sku,

      price: (price as MoneyModel).toDomain(),
      discountPrice: (discountPrice as MoneyModel?)?.toDomain(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      stock: stock,
      image: (image as ProductImageModel?)?.toDomain(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'attributes': attributes,
      'sku': sku,
      'price': price.value,
      'discount_price': discountPrice?.value,
      'stock': stock,
      'image_id': image?.id,
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    final data = toJson();

    data.remove('id');

    if (data['image_id'] == null) {
      data.remove('image_id');
    }
    return data;
  }

  Map<String, dynamic> toJsonWithStockDistribution(bool isDistribution) {
    final data = toJson();

    if (isDistribution) {
      data['is_part_of_distribution'] = true;
    }

    return data;
  }

  // Helper methods
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static Map<String, String> _parseAttributes(dynamic attributesData) {
    Map<String, String> result = {};

    if (attributesData == null) return result;

    if (attributesData is Map) {
      attributesData.forEach((key, value) {
        if (value != null) {
          result[key.toString()] = value.toString();
        }
      });
    }
    return result;
  }

  bool validateVariantPrice(double productPrice, bool allowPriceIncrease) {
    if (price.value <= 0) return false;

    if (price.value > productPrice && !allowPriceIncrease) {
      return false;
    }

    if (discountPrice != null && discountPrice!.value >= price.value) {
      return false;
    }

    return true;
  }
}
