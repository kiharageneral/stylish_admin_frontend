import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parent;
  final String? parentName;
  final String? slug;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.parent,
    this.parentName,
    this.slug,
  });

  // Helper method to check if this is a root category
  bool get isRootCategory => parent == null;

  // Helper method to get display name (with parent if applicable)
  String get displayName {
    if (parentName != null) {
      return '$name (in $parentName)';
    }
    return name;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        image,
        isActive,
        createdAt,
        updatedAt,
        parent,
        parentName,
        slug
      ];
}
