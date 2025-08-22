
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:stylish_admin/core/constants/api_endpoints.dart';
import 'package:stylish_admin/core/errors/exceptions.dart';
import 'package:stylish_admin/core/network/api_client.dart';
import 'package:stylish_admin/core/utils/web_image_utils.dart';
import 'package:stylish_admin/features/category/data/models/category_model.dart';
import 'package:stylish_admin/features/category/data/models/paginated_response_model.dart';
import 'package:http_parser/http_parser.dart';

abstract class CategoryRemoteDataSource {
  Future<PaginatedResponse<CategoryModel>> getCategories({int page = 1, int pageSize = 20});
  Future<CategoryModel> createCategory(
    String name, {
    String? description,
    String? parent,
    bool isActive = true,
    Map<String, dynamic>? image,
  });
  Future<void> deleteCategory(String id);
  Future<CategoryModel> updateCategory(
    String id, {
    String? name,
    String? description,
    String? parentId,
    bool? isActive,
    Map<String, dynamic>? image,
    bool deleteImage = false,
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient client;

  CategoryRemoteDataSourceImpl({required this.client});

  @override
  Future<PaginatedResponse<CategoryModel>> getCategories({int page = 1, int pageSize = 20}) async {
    try {
      final params = {'page': page.toString(), 'page_size': pageSize.toString()};
      final response = await client.get(ApiEndpoints.categories, queryParameters: params);

      if (response is Map<String, dynamic> && response.containsKey('results')) {
        return PaginatedResponse<CategoryModel>.fromJson(response, (json) => CategoryModel.fromJson(json));
      } else if (response is List) {
        final categories = response.map((json) => CategoryModel.fromJson(json)).toList();
        return PaginatedResponse<CategoryModel>(
            count: categories.length, next: null, previous: null, results: categories);
      }
      throw ServerException(message: 'Invalid response format for categories.');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to fetch categories: ${e.toString()}');
    }
  }

  @override
  Future<CategoryModel> createCategory(
    String name, {
    String? description,
    String? parent,
    bool isActive = true,
    Map<String, dynamic>? image,
  }) async {
    try {
      final fields = {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'is_active': isActive,
        'parent': parent,
      };

      dynamic requestData;
      if (image != null && image.containsKey('data')) {
        final String dataUrl = image['data'];
        final Uint8List bytes = WebImageUtils.extractBytesFromDataUrl(dataUrl);

        if (!WebImageUtils.validateImageSize(bytes)) {
          throw ServerException(message: 'Image size exceeds the maximum limit of 2MB');
        }
        final String? mimeType = WebImageUtils.extractMimeTypeFromDataUrl(dataUrl);

        requestData = FormData.fromMap({
          ...fields,
          'image': MultipartFile.fromBytes(
            bytes,
            filename: image['name'] ?? 'category_image.jpg',
            contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
          ),
        });
      } else {
        requestData = fields;
      }

      final response = await client.post(ApiEndpoints.categories, data: requestData);
      return CategoryModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to create category: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await client.delete('${ApiEndpoints.categories}$id/');
    } catch (e) {
      throw ServerException(message: 'Failed to delete category: ${e.toString()}');
    }
  }

  @override
  Future<CategoryModel> updateCategory(
    String id, {
    String? name,
    String? description,
    String? parentId,
    bool? isActive,
    Map<String, dynamic>? image,
    bool deleteImage = false,
  }) async {
    try {
      final fields = <String, dynamic>{};
      if (name != null) fields['name'] = name;
      if (description != null) fields['description'] = description;
      if (isActive != null) fields['is_active'] = isActive;
      if (deleteImage) fields['delete_image'] = true;
      if (parentId != null) fields['parent'] = parentId.isEmpty ? null : parentId;

      dynamic requestData;
      if (image != null && image.containsKey('data')) {
        final String dataUrl = image['data'];
        final Uint8List bytes = WebImageUtils.extractBytesFromDataUrl(dataUrl);
        if (!WebImageUtils.validateImageSize(bytes)) {
          throw ServerException(message: 'Image size exceeds the maximum limit of 2MB');
        }
        final String? mimeType = WebImageUtils.extractMimeTypeFromDataUrl(dataUrl);

        requestData = FormData.fromMap({
          ...fields,
          'image': MultipartFile.fromBytes(
            bytes,
            filename: image['name'] ?? 'category_image.jpg',
            contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
          ),
        });
      } else {
        requestData = fields;
      }

      final response = await client.patch('${ApiEndpoints.categories}$id/', data: requestData);
      return CategoryModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to update category: ${e.toString()}');
    }
  }
}