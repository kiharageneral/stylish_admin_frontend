part of 'product_variant_bloc.dart';

abstract class ProductVariantEvent extends Equatable {
  const ProductVariantEvent();

  @override
  List<Object?> get props => [];
}

// Initializes the BLoC state for the variations UI
class InitializeVariationsDataEvent extends ProductVariantEvent {
  final String productId;
  final Map<String, List<String>> initialVariations;
  final List<ProductVariantEntity>? initialVariants;
  final List<String>? initialSizes;
  final double basePrice;
  final int currentStock;

  const InitializeVariationsDataEvent({
    required this.productId,
    required this.initialVariations,
    this.initialVariants,
    required this.initialSizes,
    required this.basePrice,
    required this.currentStock,
  });

  @override
  List<Object?> get props => [
    productId,
    initialVariations,
    initialVariants,
    initialSizes,
    basePrice,
    currentStock,
  ];
}

// Adds a new variation type (e.g., 'Color') and its values
class AddVariationDefinitionEvent extends ProductVariantEvent {
  final String name;
  final List<String> values;

  const AddVariationDefinitionEvent({required this.name, required this.values});
  @override
  List<Object?> get props => [name, values];
}

// Removes a whole variation type (e.g., 'Color')
class RemoveVariationDefinitionEvent extends ProductVariantEvent {
  final ProductVariationsEntity variation;

  const RemoveVariationDefinitionEvent(this.variation);

  @override
  List<Object?> get props => [variation];
}

// Removes a single value from a variation (e.g., 'Red' from 'Color')
class RemoveVariationValueEvent extends ProductVariantEvent {
  final ProductVariationsEntity variation;
  final String value;

  const RemoveVariationValueEvent({required this.variation, required this.value});

  @override
  List<Object?> get props => [variation, value];
}

// Updates the values for the 'Size' variation
class UpdateSizesDefinitionEvent extends ProductVariantEvent {
  final List<String> sizes;

  const UpdateSizesDefinitionEvent(this.sizes);

  @override
  List<Object?> get props => [sizes];
}

// Updates local variants state from the UI without saving to the backend
class LocalVariantsUpdatedEvent extends ProductVariantEvent {
  final List<ProductVariantEntity> variants;

  const LocalVariantsUpdatedEvent(this.variants);

  @override
  List<Object?> get props => [variants];
}

// Saves all local changes (definitions and variants) to the backend
class SaveVariationsEvent extends ProductVariantEvent {}

// Distribute the product's total stock across all variants
class DistributeStockAcrossVariantsEvent extends ProductVariantEvent {
  final int totalStock;

  const DistributeStockAcrossVariantsEvent(this.totalStock);

  @override
  List<Object?> get props => [totalStock];
}

class GetProductVariantsEvent extends ProductVariantEvent {
  final String productId;

  const GetProductVariantsEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class GetVariantByIdEvent extends ProductVariantEvent {
  final String variantId;

  const GetVariantByIdEvent(this.variantId);

  @override
  List<Object?> get props => [variantId];
}

class CreateProductVariantEvent extends ProductVariantEvent {
  final String productId;
  final ProductVariantEntity variant;
  final dynamic variantImage;

  const CreateProductVariantEvent({
    required this.productId,
    required this.variant,
    this.variantImage,
  });

  @override
  List<Object?> get props => [productId, variant, variantImage];
}

class DistributeProductStockEvent extends ProductVariantEvent {
  final String productId;
  final List<ProductVariantEntity> variants;
  final int totalStock;

  const DistributeProductStockEvent({
    required this.productId,
    required this.variants,
    required this.totalStock,
  });

  @override
  List<Object?> get props => [productId, variants, totalStock];
}

class UpdateProductVariantEvent extends ProductVariantEvent {
  final String variantId;
  final ProductVariantEntity variant;
  final dynamic variantImage;

  const UpdateProductVariantEvent({
    required this.variantId,
    required this.variant,
    this.variantImage,
  });

  @override
  List<Object?> get props => [variantId, variant, variantImage];
}

class DeleteProductVariantEvent extends ProductVariantEvent {
  final String productId;
  final String variantId;

  const DeleteProductVariantEvent({
    required this.productId,
    required this.variantId,
  });

  @override
  List<Object?> get props => [productId, variantId];
}

class ManageProductVariantEvent extends ProductVariantEvent {
  final String id;
  final Map<String, dynamic> variantsData;

  const ManageProductVariantEvent({
    required this.id,
    required this.variantsData,
  });

  @override
  List<Object?> get props => [id, variantsData];
}

class UpdateVariantStockEvent extends ProductVariantEvent {
  final String variantId;
  final int newStock;
  final String? reason;

  const UpdateVariantStockEvent({
    required this.variantId,
    required this.newStock,
    this.reason,
  });
  @override
  List<Object?> get props => [variantId, newStock, reason];
}

class UpdateVariantPriceEvent extends ProductVariantEvent {
  final String variantId;
  final double price;
  final double? discountPrice;

  const UpdateVariantPriceEvent({
    required this.variantId,
    required this.price,
    this.discountPrice,
  });

  @override
  List<Object?> get props => [variantId, price, discountPrice];
}

class ClearVariantErrorEvent extends ProductVariantEvent {}

class ClearVariantOperationSuccessEvent extends ProductVariantEvent {}

class ResetVariantStateEvent extends ProductVariantEvent {}

class BatchUpdateDiscountsEvent extends ProductVariantEvent {
  final String productId;
  final List<ProductVariantEntity> variants;

  const BatchUpdateDiscountsEvent({
    required this.productId,
    required this.variants,
  });

  @override
  List<Object?> get props => [productId, variants];
}
