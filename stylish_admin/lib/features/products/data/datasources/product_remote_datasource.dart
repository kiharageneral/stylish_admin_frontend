import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stylish_admin/core/constants/api_endpoints.dart';
import 'package:stylish_admin/core/errors/exceptions.dart';
import 'package:stylish_admin/core/network/api_client.dart';
import 'package:stylish_admin/core/utils/web_image_utils.dart';
import 'package:stylish_admin/features/products/data/models/paginated_product_model.dart';
import 'package:stylish_admin/features/products/data/models/product_filter_model.dart';
import 'package:stylish_admin/features/products/data/models/product_image_model.dart';
import 'package:stylish_admin/features/products/data/models/product_model.dart';

abstract class ProductRemoteDatasource {
  Future<PaginatedProductModel> getProductsPaginated(
    Map<String, dynamic> params,
  );

  Future<ProductModel> getProductById(String id);

  Future<ProductModel> createProduct(
    ProductModel product, {
    List<dynamic>? images,
  });

  Future<ProductModel> updateProduct(
    String id,
    ProductModel product, {
    List<dynamic>? newImages,
    List<String>? removedImageIds,
  });
  Future<bool> deleteProduct(String id);

  Future<bool> updateProductStock(String id, int newStock, String reason);
  Future<ProductModel> updateProductPrice(
    String id, {
    required double price,
    double? discountPrice,
  });

  Future<bool> toggleProductStatus(String id);

  Future<ProductModel> updateProductProfitMargin(
    String id, {
    required double cost,
    required double price,
    double? discountPrice,
    required double profitMargin,
  });

  Future<bool> deleteProductImage(String productId, String imageId);

  Future<bool> bulkDeleteProducts(List<String> productIds);

  Future<List<CategoryModel>> getProductCategories();

  Future<ProductFilterModel> getProductFilters();

  Future<List<ProductImageModel>> manageProductImages(
    String id, {
    required List<dynamic> images,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDatasource {
  final ApiClient client;

  ProductRemoteDataSourceImpl({required this.client});

  @override
  Future<bool> bulkDeleteProducts(List<String> productIds) async {
    await client.post(
      ApiEndpoints.bulkDelete,
      data: {'product_ids': productIds},
    );
    return true;
  }

  @override
  Future<ProductModel> createProduct(
    ProductModel product, {
    List? images,
  }) async {
    final fields = product.toJsonForCreate();
    dynamic requestData;

    if (images != null && images.isNotEmpty) {
      final formFields = fields.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      final List<MapEntry<String, MultipartFile>> fileEntries = [];
      for (int i = 0; i < images.length; i++) {
        var image = images[i];
        if (image is Map<String, dynamic> && image.containsKey('data')) {
          final Uint8List bytes = WebImageUtils.extractBytesFromDataUrl(
            image['data'],
          );
          final String fileName = image['name'] ?? 'product_image_$i.jpg';
          fileEntries.add(
            MapEntry(
              'images',
              MultipartFile.fromBytes(bytes, filename: fileName),
            ),
          );
          if (image['is_primary'] == true) {
            formFields['primary_image_index'] = i.toString();
          }
        }
      }
      requestData = FormData.fromMap(formFields)..files.addAll(fileEntries);
    } else {
      requestData = fields;
    }

    final response = await client.post(
      ApiEndpoints.productList,
      data: requestData,
    );
    return ProductModel.fromJson(response);
  }

  @override
  Future<bool> deleteProduct(String id) async {
    final endpoint = ApiEndpoints.formatUrl(ApiEndpoints.productDetail, id);
    await client.delete(endpoint);
    return true;
  }

  @override
  Future<bool> deleteProductImage(String productId, String imageId) async {
    final endpoint = ApiEndpoints.formatUrl(
      ApiEndpoints.deleteImage,
      productId,
    );
    await client.post(endpoint, data: {'image_id': imageId});
    return true;
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final endpoint = ApiEndpoints.formatUrl(ApiEndpoints.productDetail, id);
    final response = await client.get(endpoint);
    // print(response);
    return ProductModel.fromJson(response);
  }

  @override
  Future<List<CategoryModel>> getProductCategories() async {
    final response = await client.get(ApiEndpoints.categories);
    if (response is List) {
      return response
          .map((category) => CategoryModel.fromJson(category))
          .toList();
    } else if (response is Map<String, dynamic> &&
        response.containsKey('results')) {
      final categories = response['results'] as List;
      return categories
          .map((category) => CategoryModel.fromJson(category))
          .toList();
    }
    throw ServerException(message: 'Unexpected format for categories response');
  }

  @override
  Future<ProductFilterModel> getProductFilters() async {
    final response = await client.get(ApiEndpoints.productFilters);
    return ProductFilterModel.fromJson(response);
  }

  @override
  Future<PaginatedProductModel> getProductsPaginated(
    Map<String, dynamic> params,
  ) async {
    final response = await client.get(
      ApiEndpoints.productList,
      queryParameters: params,
    );
    return PaginatedProductModel.fromJson(response);
  }

  @override
  Future<List<ProductImageModel>> manageProductImages(
    String id, {
    required List<dynamic> images,
  }) async {
    final endpoint = ApiEndpoints.formatUrl(ApiEndpoints.manageImages, id);
    final formFields = <String, String>{};

    final List<MapEntry<String, MultipartFile>> fileEntries = [];

    for (int i = 0; i < images.length; i++) {
      var image = images[i];
      if (image is Map<String, dynamic> && image.containsKey('data')) {
        final Uint8List bytes = WebImageUtils.extractBytesFromDataUrl(
          image['data'],
        );
        final String fileName = image['name'] ?? 'product_name_$i.jpg';
        fileEntries.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(bytes, filename: fileName),
          ),
        );
        if (image['is_primary'] == true) {
          formFields['primary_image_index'] = i.toString();
        }
      }
    }

    final requestData = FormData.fromMap(formFields)..files.addAll(fileEntries);
    final response = await client.post(endpoint, data: requestData);
    if (response is List) {
      return response.map((img) => ProductImageModel.fromJson(img)).toList();
    }
    throw ServerException(
      message: 'Expected a list of images but got something else',
    );
  }

  @override
  Future<bool> toggleProductStatus(String id) async {
    final endpoint = ApiEndpoints.formatUrl(ApiEndpoints.productDetail, id);
    await client.patch(endpoint, data: {'is_active': null});
    return true;
  }

  @override
  Future<ProductModel> updateProduct(
    String id,
    ProductModel product, {
    List? newImages,
    List<String>? removedImageIds,
  }) async {
    final endpoint = ApiEndpoints.formatUrl(ApiEndpoints.productDetail, id);
    final fields = product.toJsonForUpdate();

    if (removedImageIds != null && removedImageIds.isNotEmpty) {
      fields['removed_image_ids'] = removedImageIds;
    }

    dynamic requestData;

    if (newImages != null && newImages.isNotEmpty) {
      final formFields = fields.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      final List<MapEntry<String, MultipartFile>> fileEntries = [];

      for (int i = 0; i < newImages.length; i++) {
        var image = newImages[i];
        if (image is Map<String, dynamic> && image.containsKey('data')) {
          final Uint8List bytes = WebImageUtils.extractBytesFromDataUrl(
            image['data'],
          );
          final String fileName = image['name'] ?? 'new_image_$i.jpg';
          fileEntries.add(
            MapEntry(
              'new_images',
              MultipartFile.fromBytes(bytes, filename: fileName),
            ),
          );
          if (image['is_primary'] == true) {
            formFields['primary_image_index'] = i.toString();
          }
        }
      }
      requestData = FormData.fromMap(formFields)..files.addAll(fileEntries);
    } else {
      requestData = fields;
    }

    final response = await client.patch(endpoint, data: requestData);
    
    return ProductModel.fromJson(response);
  }

  @override
  Future<ProductModel> updateProductPrice(
    String id, {
    required double price,
    double? discountPrice,
  }) async {
    final endpoint = ApiEndpoints.formatUrl(ApiEndpoints.productDetail, id);
    final body = {'price': price};

    if (discountPrice != null) {
      body['discount_price'] = discountPrice;
    }

    final response = await client.patch(endpoint, data: body);
    return ProductModel.fromJson(response);
  }

  @override
  Future<ProductModel> updateProductProfitMargin(
    String id, {
    required double cost,
    required double price,
    double? discountPrice,
    required double profitMargin,
  }) async {
    final endpoint = ApiEndpoints.formatUrl(ApiEndpoints.productDetail, id);
    final Map<String, dynamic> body = {
      'cost': cost,
      'price': price,
      'profit_margin': profitMargin,
    };

    if (discountPrice != null) {
      body['discount_price'] = discountPrice;
    }

    final response = await client.patch(endpoint, data: body);
    return ProductModel.fromJson(response);
  }

  @override
  Future<bool> updateProductStock(
    String id,
    int newStock,
    String reason,
  ) async {
    final endpoint = ApiEndpoints.formatUrl(ApiEndpoints.stockAdjustment, id);
    await client.post(endpoint, data: {'quantity': newStock, 'reason': reason});
    return true;
  }
}
