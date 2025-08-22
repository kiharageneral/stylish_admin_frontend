import 'package:flutter/foundation.dart';
import 'package:stylish_admin/features/products/data/models/product_model.dart';
import 'package:stylish_admin/features/products/domain/entities/paginated_products_entity.dart';

class PaginatedProductModel extends PaginatedProductsEntity {
  const PaginatedProductModel({
    required super.products,
    required super.totalCount,
    required super.currentPage,
    required super.totalPages,
    required super.pageSize,
    required super.hasNextPage,
    required super.hasPreviousPage,
  });

  factory PaginatedProductModel.fromJson(Map<String, dynamic> json) {
    try {
      final results = json['results'] as List<dynamic>? ?? [];
      final totalCount = json['total_items'] as int? ?? 0;
      final currentPage = json['current_page'] as int? ?? 1;
      final totalPages = json['total_pages'] as int? ?? 1;
      final pageSize = json['page_size'] as int? ?? results.length;
      final hasNextPage = json['next'] != null;
      final hasPreviousPage = json['previous'] != null;

      return PaginatedProductModel(
        products: results
            .map((product) => ProductModel.fromJson(product))
            .toList(),
        totalCount: totalCount,
        currentPage: currentPage,
        totalPages: totalPages,
        pageSize: pageSize,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error parsing paginated products: $e');
        print('JSON: $json');
        print('Stack trace: $stackTrace');
      }
      return PaginatedProductModel.empty();
    }
  }

  factory PaginatedProductModel.empty() {
    return const PaginatedProductModel(
      products: [],
      totalCount: 0,
      currentPage: 1,
      totalPages: 1,
      pageSize: 20,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  PaginatedProductModel toDomain() {
    return PaginatedProductModel(
      products: products.map((e) => (e as ProductModel).toDomain()).toList(),
      totalCount: totalCount,
      currentPage: currentPage,
      totalPages: totalPages,
      pageSize: pageSize,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }
}
