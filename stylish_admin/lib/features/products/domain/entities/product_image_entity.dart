import 'package:equatable/equatable.dart';

class ProductImageEntity extends Equatable {
  final String id;
  final String? productId;
  final String imageUrl;
  final String altText;
  final int order;
  final bool isPrimary;
  final DateTime? createdAt;

  const ProductImageEntity({
    required this.id,
    this.productId,
    required this.imageUrl,
    required this.altText,
    this.order = 0,
    required this.isPrimary,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    imageUrl,
    altText,
    order,
    isPrimary,
    createdAt,
  ];

  ProductImageEntity copyWith({
    String? id,
    String? productId,
    String? imageUrl,
    String? altText,
    int? order,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return ProductImageEntity(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      altText: altText ?? this.altText,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
