import 'package:flutter/foundation.dart';
import 'package:stylish_admin/features/products/domain/entities/product_image_entity.dart';

class ProductImageModel extends ProductImageEntity {
  const ProductImageModel({
    required super.id,
    required super.imageUrl,
    super.productId,
    super.createdAt,
    super.order,
    required super.altText,
    required super.isPrimary,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProductImageModel(
        id: json['id']?.toString() ?? '0',
        imageUrl: json['image_url'] ?? '',
        altText: json['alt_text'] ?? '',
        isPrimary: json['is_primary'] is bool ? json['is_primary'] : false,
        productId: json['product_id']?.toString(),
        order: json['order'] is int ? json['order'] : 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsion image data: $e');
        print('JSON: $json');
      }
      return ProductImageModel(
        id: '0',
        imageUrl: json['imag_url'] ?? '',
        altText: '',
        isPrimary: false,
        createdAt: DateTime.now(),
        order: 0, 
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image_url': imageUrl,
      'alt_text': altText,
      'order': order,
      'is_primary': isPrimary,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ProductImageEntity toDomain() {
    return ProductImageEntity(
      id: id,
      imageUrl: imageUrl,
      altText: altText,
      isPrimary: isPrimary,
    );
  }
}
