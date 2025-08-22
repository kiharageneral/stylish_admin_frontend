import 'package:equatable/equatable.dart';

class ProductVariationsEntity extends Equatable {
  final String id;
  final String name;
  final List<String> values;

  const ProductVariationsEntity({
    required this.id,
    required this.name,
    required this.values,
  });
  @override
  List<Object?> get props => [id, name, values];

  ProductVariationsEntity copyWith({
    String? id,
    String? name,
    List<String>? values,
  }) {
    return ProductVariationsEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      values: values ?? this.values,
    );
  }
}
