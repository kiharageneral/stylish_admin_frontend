import 'package:stylish_admin/features/variations/domain/entities/product_variations_entity.dart';

class ProductVariationModel extends ProductVariationsEntity {
  const ProductVariationModel({
    required super.id,
    required super.name,
    required super.values,
  });

  factory ProductVariationModel.fromJson(Map<String, dynamic> json) {
    return ProductVariationModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      values: (json['values'] as List).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'values': values};
  }

  ProductVariationsEntity toDomain() {
    return ProductVariationsEntity(id: id, name: name, values: values);
  }

  factory ProductVariationModel.create({
    required String name,
    required List<String> values,
  }) {
    return ProductVariationModel(id: '', name: name, values: values);
  }
}
