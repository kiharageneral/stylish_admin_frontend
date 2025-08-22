import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel(
      {required super.id,
      required super.name,
      super.description,
      super.image,
      required super.isActive,
      required super.createdAt,
      required super.updatedAt,
      super.parent,
      super.parentName,
      super.slug});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? parentId;
    String? parentName;

    if (json['parent'] != null && json['parent'] != 'null') {
      if (json['parent'] is String) {
        parentId = json['parent'];
      } else if (json['parent'] is Map) {
        parentId = json['parent']['id']?.toString();
        parentName = json['parent']['name'];
      }
    }

    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image_url'],
      isActive: json['is_active'] ?? true, 
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      parent: parentId,
      parentName: json['parent_name'] ?? parentName,
      slug: json['slug'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'is_active': isActive,
      if (parent != null) 'parent': parent,
    };
  }

  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'parent': parent,
      'slug': slug,
    };
  }

  factory CategoryModel.fromEntity(CategoryEntity category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      image: category.image,
      isActive: category.isActive,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      parent: category.parent,
      parentName: category.parentName,
      slug: category.slug,
    );
  }
}
