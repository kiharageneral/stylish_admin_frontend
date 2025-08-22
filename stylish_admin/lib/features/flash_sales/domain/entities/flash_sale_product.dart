import 'package:equatable/equatable.dart';

class FlashProduct extends Equatable {
  final String id;
  final String name;
  final double price;
  final bool isActive;
  final String? categoryName;
  final int? stock;
  final String? primaryImageUrl;

  const FlashProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
    this.categoryName,
    this.stock,
    this.primaryImageUrl,
  });

  FlashProduct copyWith({
    String? id,
    String? name,
    double? price,
    bool? isActive,
    String? categoryName,
    int? stock,
    String? primaryImageUrl,
  }) {
    return FlashProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      categoryName: categoryName ?? this.categoryName,
      stock: stock ?? this.stock,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    isActive,
    categoryName,
    stock,
    primaryImageUrl,
  ];
}
