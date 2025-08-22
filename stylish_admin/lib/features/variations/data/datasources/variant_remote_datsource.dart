import 'package:stylish_admin/core/constants/api_endpoints.dart';
import 'package:stylish_admin/core/errors/exceptions.dart';
import 'package:stylish_admin/core/network/api_client.dart';
import 'package:stylish_admin/features/variations/data/models/product_variant_model.dart';

abstract class VariantRemoteDataSource {
  Future<Map<String, dynamic>> manageProductVariants(
    String productId,
    Map<String, dynamic> variantsData,
  );
  Future<ProductVariantModel> createProductVariant(
    String productId,
    Map<String, dynamic> variantData,
  );
  Future<ProductVariantModel> updateProductVariant(
    String variantId,
    Map<String, dynamic> variantData,
  );

  Future<bool> deleteProductVariant(String productId, String variantId);
  Future<List<ProductVariantModel>> getProductVariants(String productId);
  Future<Map<String, dynamic>> distributeProductStock(
    String productId,
    Map<String, dynamic> variantsData,
  );
}

class VariantRemoteDataSourceImpl implements VariantRemoteDataSource {
  final ApiClient client;

  VariantRemoteDataSourceImpl({required this.client});
  @override
  Future<ProductVariantModel> createProductVariant(
    String productId,
    Map<String, dynamic> variantData,
  ) async {
    try {
      final endpoint = ApiEndpoints.manageProductVariants.replaceAll(
        '{id}',
        productId,
      );

      final payload = {
        'variants': [variantData],
        'variations': {},
      };

      final response = await client.post(endpoint, data: payload);

      final variants = response['variants'] as List;
      if (variants.isNotEmpty) {
        return ProductVariantModel.fromJson(variants.last);
      }

      throw ServerException(message: 'Created variant not found in response');
    } catch (e) {
      throw ServerException(
        message: 'Failed to create product variant: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> deleteProductVariant(String productId, String variantId) async {
    try {
      final endpoint = ApiEndpoints.manageProductVariants.replaceAll(
        '{id}',
        productId,
      );
      final payload = {'delete_variant_id': variantId};
      final response = await client.post(endpoint, data: payload);
      return response != null;
    } catch (e) {
      throw ServerException(
        message: 'Failed to delete product variant: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> distributeProductStock(
    String productId,
    Map<String, dynamic> variantsData,
  ) async {
    try {
      final endpoint = ApiEndpoints.distributeStock.replaceAll(
        '{id}',
        productId,
      );

      // Ensure the distribution flag is included
      variantsData['is_stock_distribution'] = true;
      final response = await client.post(endpoint, data: variantsData);
      return response;
    } catch (e) {
      throw ServerException(
        message: 'Failed to distribute product stock: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ProductVariantModel>> getProductVariants(String productId) async {
    try {
      final endpoint = ApiEndpoints.productVariants.replaceAll(
        '{id}',
        productId,
      );
      final response = await client.get(endpoint);
      final List<dynamic> variantsJson = response ?? [];
      return variantsJson
          .map((json) => ProductVariantModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch product variants: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> manageProductVariants(
    String productId,
    Map<String, dynamic> variantsData,
  ) async {
    try {
      if (productId.isEmpty) {
        throw ServerException(message: "Product ID cannot be empty");
      }
      final endpoint = ApiEndpoints.manageProductVariants.replaceAll(
        '{id}',
        productId,
      );
      final response = await client.post(endpoint, data: variantsData);
      return response;
    } catch (e) {
      throw ServerException(
        message: 'Failed to manage product variants : ${e.toString()}',
      );
    }
  }

  @override
  Future<ProductVariantModel> updateProductVariant(
    String variantId,
    Map<String, dynamic> variantData,
  ) async {
    try {
      final String productId =
          variantData['product_id'] ??
          variantData['productId'] ??
          variantData['product'] ??
          '';

      if (productId.isEmpty) {
        throw ServerException(
          message: 'Product ID is required to update a variant',
        );
      }

      final endpoint = ApiEndpoints.manageProductVariants.replaceAll(
        '{id}',
        productId,
      );

      variantData['id'] = variantId;
      final payload = {
        'variants': [variantData],
        'variations': {},
      };
      final response = await client.post(endpoint, data: payload);

      // Find the updated variant in the response
      final variants = response['variants'] as List;

      final updatedVariant = variants.firstWhere(
        (v) => v['id'] == variantId,
        orElse: () => throw ServerException(
          message: 'Update variant not found in response',
        ),
      );
      return ProductVariantModel.fromJson(updatedVariant);
    } catch (e) {
      throw ServerException(
        message: 'Failed to update product variant: ${e.toString()}',
      );
    }
  }
}
