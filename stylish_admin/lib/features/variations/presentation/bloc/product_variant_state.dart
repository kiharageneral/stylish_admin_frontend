//  Variation definitions - the abstract options you offer (e.g., Color, Size)
//  Product Variants - The concrete, sellable combinations that result from those definitions (e.g., Color: Red, Size: Medium)

part of 'product_variant_bloc.dart';

class ProductVariantState extends Equatable {
  final List<ProductVariantEntity>? variants;
  final ProductVariantEntity? currentVariant;
  final String? errorMessage;
  final bool isLoading;
  final bool isOperationLoading;
  final bool isOperationSuccess;
  final List<ProductVariationsEntity> variations;
  final bool isDirty;
  final String productId;
  final double basePrice;

  const ProductVariantState({
    this.variants,
    this.currentVariant,
    this.errorMessage,
    this.isLoading = false,
    this.isOperationLoading = false,
    this.isOperationSuccess = false,
    this.variations = const [],
    this.isDirty = false,
    this.productId = '',
    this.basePrice = 0.0,
  });

  @override
  List<Object?> get props => [
    variants,
    currentVariant,
    errorMessage,
    isLoading,
    isOperationLoading,
    isOperationSuccess,
    variations,
    isDirty,
    productId,
    basePrice,
  ];

  ProductVariantState copyWith({
    List<ProductVariantEntity>? variants,
    ProductVariantEntity? currentVariant,
    String? errorMessage,
    bool? isLoading,
    bool? isOperationLoading,
    bool? isOperationSuccess,
    List<ProductVariationsEntity>? variations,
    bool? isDirty,
    String? productId,
    double? basePrice,
    bool clearError = false,
    bool clearOperationSuccess = false,
    bool clearCurrentVariant = false,
  }) {
    return ProductVariantState(
      variants: variants ?? this.variants,
      currentVariant: clearCurrentVariant
          ? null
          : (currentVariant ?? this.currentVariant),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      isOperationSuccess: clearOperationSuccess
          ? false
          : (isOperationSuccess ?? this.isOperationSuccess),
      variations: variations ?? this.variations,
      productId: productId ?? this.productId,
      basePrice: basePrice ?? this.basePrice,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class ProductVariantInitial extends ProductVariantState{}