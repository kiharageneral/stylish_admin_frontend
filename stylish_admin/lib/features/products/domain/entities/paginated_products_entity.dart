import 'package:equatable/equatable.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';

class PaginatedProductsEntity extends Equatable {
  final List<ProductEntity> products;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedProductsEntity({
    required this.products,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  @override
  List<Object?> get props => [
    products,
    totalCount,
    currentPage,
    totalPages,
    pageSize,
    hasNextPage,
    hasPreviousPage,
  ];

  PaginatedProductsEntity copyWith({
    List<ProductEntity>? products,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    int? pageSize,
    bool? hasNextPage,
    bool? hasPreviousPage,
  }) {
    return PaginatedProductsEntity(
      products: products ?? this.products,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      pageSize: pageSize ?? this.pageSize,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
    );
  }
}
