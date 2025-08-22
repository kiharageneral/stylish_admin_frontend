import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/event_bus/app_event_bus.dart';
import 'package:stylish_admin/features/products/domain/entities/money_entity.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variations_entity.dart';
import 'package:stylish_admin/features/variations/domain/usecases/create_product_variant.dart';
import 'package:stylish_admin/features/variations/domain/usecases/delete_product_variant.dart';
import 'package:stylish_admin/features/variations/domain/usecases/distribution_use_case.dart';
import 'package:stylish_admin/features/variations/domain/usecases/get_product_variants.dart';
import 'package:stylish_admin/features/variations/domain/usecases/manage_product_variants.dart';
import 'package:stylish_admin/features/variations/domain/usecases/update_product_variants.dart';
import 'package:uuid/uuid.dart';

part 'product_variant_event.dart';
part 'product_variant_state.dart';

class ProductVariantBloc
    extends Bloc<ProductVariantEvent, ProductVariantState> {
  final GetProductVariants getProductVariants;
  final CreateProductVariant createProductVariant;
  final UpdateProductVariant updateProductVariant;
  final DeleteProductVariant deleteProductVariant;
  final ManageProductVariants manageProductVariants;
  final DistributeProductStockUseCase distributeProductStockUseCase;

  final _uuid = const Uuid();

  ProductVariantBloc({
    required this.getProductVariants,
    required this.createProductVariant,
    required this.updateProductVariant,
    required this.deleteProductVariant,
    required this.manageProductVariants,
    required this.distributeProductStockUseCase,
  }) : super(ProductVariantInitial()) {
    on<InitializeVariationsDataEvent>(_onInitializeVariationsData);
    on<AddVariationDefinitionEvent>(_onAddVariationDefinition);
    on<RemoveVariationDefinitionEvent>(_onRemoveVariationDefinition);
    on<RemoveVariationValueEvent>(_onRemoveVariationValue);
    on<UpdateSizesDefinitionEvent>(_onUpdateSizesDefinition);
    on<LocalVariantsUpdatedEvent>(_onLocalVariantsUpdated);
    on<SaveVariationsEvent>(_onSaveVariations);
    on<DistributeStockAcrossVariantsEvent>(_onDistributeStockAcrossVariants);

    on<GetProductVariantsEvent>(_onGetProductVariants);
    on<GetVariantByIdEvent>(_onGetVariantById);
    on<CreateProductVariantEvent>(_onCreateProductVariant);
    on<UpdateProductVariantEvent>(_onUpdateProductVariant);
    on<DeleteProductVariantEvent>(_onDeleteProductVariant);
    on<ManageProductVariantEvent>(_onManageProductVariants);
    on<UpdateVariantStockEvent>(_onUpdateVariantStock);
    on<UpdateVariantPriceEvent>(_onUpdateVariantPrice);
    on<ClearVariantErrorEvent>(_onClearVariantError);
    on<ClearVariantOperationSuccessEvent>(_onClearOperationSuccess);
    on<ResetVariantStateEvent>(_onResetVariantState);
    on<DistributeProductStockEvent>(_onDistributeProductStock);
    on<BatchUpdateDiscountsEvent>(_onBatchUpdateDiscounts);
  }

  void _onInitializeVariationsData(
    InitializeVariationsDataEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    List<ProductVariationsEntity> initialVariations = event
        .initialVariations
        .entries
        .map((entry) {
          return ProductVariationsEntity(
            id: _uuid.v4(),
            name: entry.key,
            values: entry.value,
          );
        })
        .toList();
    List<ProductVariantEntity> initialVariants = event.initialVariants ?? [];

    if (initialVariants.isEmpty && initialVariations.isNotEmpty) {
      initialVariants = _generateAllVariantCombinations(
        variations: initialVariations,
        productId: event.productId,
        basePrice: event.basePrice,
        currentStock: event.currentStock,
      );
    }

    emit(
      state.copyWith(
        variations: initialVariations,
        variants: initialVariants,
        productId: event.productId,
        basePrice: event.basePrice,
        isDirty: false,
      ),
    );

    if ((event.initialVariants == null || event.initialVariants!.isEmpty) &&
        event.productId.isNotEmpty) {
      add(GetProductVariantsEvent(event.productId));
    }
  }

  void _onAddVariationDefinition(
    AddVariationDefinitionEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    if (state.variations.any(
      (v) => v.name.toLowerCase() == event.name.toLowerCase(),
    )) {
      return;
    }

    final newVariation = ProductVariationsEntity(
      id: _uuid.v4(),
      name: event.name,
      values: event.values,
    );

    final updatedVariations = [...state.variations, newVariation];

    final updatedVariants = _generateAllVariantCombinations(
      variations: updatedVariations,
      productId: state.productId,
      basePrice: state.basePrice,
      currentStock: state.variants?.fold(0, (sum, v) => sum! + v.stock) ?? 0,
    );

    emit(
      state.copyWith(
        variations: updatedVariations,
        variants: updatedVariants,
        isDirty: true,
      ),
    );
  }

  void _onRemoveVariationDefinition(
    RemoveVariationDefinitionEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    final updatedVariations = state.variations
        .where((v) => v.id != event.variation.id)
        .toList();
    final updatedVariants = _generateAllVariantCombinations(
      variations: updatedVariations,
      productId: state.productId,
      basePrice: state.basePrice,
      currentStock: state.variants?.fold(0, (sum, v) => sum! + v.stock) ?? 0,
    );

    emit(
      state.copyWith(
        variations: updatedVariations,
        variants: updatedVariants,
        isDirty: true,
      ),
    );
  }

  void _onRemoveVariationValue(
    RemoveVariationValueEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    final variationIndex = state.variations.indexWhere(
      (v) => v.id == event.variation.id,
    );
    if (variationIndex == -1) return;

    final updatedVariation = state.variations[variationIndex];
    final updatedValues = updatedVariation.values
        .where((v) => v != event.value)
        .toList();
    List<ProductVariationsEntity> updatedVariations = [...state.variations];
    if (updatedValues.isEmpty) {
      updatedVariations.removeAt(variationIndex);
    } else {
      updatedVariations[variationIndex] = updatedVariation.copyWith(
        values: updatedValues,
      );
    }

    final updatedVariants = _generateAllVariantCombinations(
      variations: updatedVariations,
      productId: state.productId,
      basePrice: state.basePrice,
      currentStock: state.variants?.fold(0, (sum, v) => sum! + v.stock) ?? 0,
    );

    emit(
      state.copyWith(
        variations: updatedVariations,
        variants: updatedVariants,
        isDirty: true,
      ),
    );
  }

  void _onUpdateSizesDefinition(
    UpdateSizesDefinitionEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    final sizeIndex = state.variations.indexWhere(
      (v) => v.name.toLowerCase() == 'size',
    );
    List<ProductVariationsEntity> updatedVariations = [...state.variations];

    if (sizeIndex != -1) {
      if (event.sizes.isEmpty) {
        updatedVariations.removeAt(sizeIndex);
      } else {
        updatedVariations[sizeIndex] = updatedVariations[sizeIndex].copyWith(
          values: event.sizes,
        );
      }
    } else if (event.sizes.isNotEmpty) {
      updatedVariations.add(
        ProductVariationsEntity(
          id: _uuid.v4(),
          name: 'Size',
          values: event.sizes,
        ),
      );
    }

    final updatedVariants = _generateAllVariantCombinations(
      variations: updatedVariations,
      productId: state.productId,
      basePrice: state.basePrice,
      currentStock: state.variants?.fold(0, (sum, v) => sum! + v.stock) ?? 0,
    );

    emit(
      state.copyWith(
        variations: updatedVariations,
        variants: updatedVariants,
        isDirty: true,
      ),
    );
  }

  void _onDistributeStockAcrossVariants(
    DistributeStockAcrossVariantsEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    if (state.variants == null || state.variants!.isEmpty) return;

    final updatedVariants = _distributeStock(
      variants: state.variants!,
      totalStock: event.totalStock,
    );

    emit(state.copyWith(variants: updatedVariants, isDirty: true));
  }

  void _onLocalVariantsUpdated(
    LocalVariantsUpdatedEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    emit(state.copyWith(variants: event.variants, isDirty: true));
  }

  void _onSaveVariations(
    SaveVariationsEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    if (state.variants == null) return;

    final productId = state.productId;

    if (productId.isEmpty) return;

    final variantsList = state.variants!.map(
      (v) => {
        'id': v.id.contains('-') ? null : v.id,
        'product': v.productId,
        'attributes': v.attributes,
        'sku': v.sku,
        'price': v.price.value,
        'discount_price': v.discountPrice?.value,
        'stock': v.stock,
        'image_id': v.image?.id,
      },
    ).toList();

    final variationsData = {
      'variations': state.variations
          .map((v) => {'name': v.name, 'values': v.values})
          .toList(),
      'variants': variantsList,
    };

    add(ManageProductVariantEvent(id: productId, variantsData: variationsData));
  }

  Future<void> _onManageProductVariants(
    ManageProductVariantEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await manageProductVariants(
      ManageVariantsParams(id: event.id, variantsData: event.variantsData),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (success) {
        add(GetProductVariantsEvent(event.id));
        emit(
          state.copyWith(
            isOperationLoading: false,
            isOperationSuccess: true,
            isDirty: false,
          ),
        );
      },
    );
  }

  Future<void> _onGetProductVariants(
    GetProductVariantsEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await getProductVariants(event.productId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        ),
      ),
      (variants) {
        final Map<String, Set<String>> extractedVariations = {};
        for (var variant in variants) {
          variant.attributes.forEach((key, value) {
            extractedVariations.putIfAbsent(key, () => {}).add(value);
          });
        }
        final newVariations = extractedVariations.entries
            .map(
              (entry) => ProductVariationsEntity(
                id: _uuid.v4(),
                name: entry.key,
                values: entry.value.toList(),
              ),
            )
            .toList();
        emit(
          state.copyWith(
            variants: variants,
            variations: newVariations,
            isLoading: false,
            isDirty: false,
          ),
        );
      },
    );
  }

  Future<void> _onGetVariantById(
    GetVariantByIdEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    if (state.variants != null) {
      try {
        final variant = state.variants!.firstWhere(
          (v) => v.id == event.variantId,
        );
        emit(state.copyWith(currentVariant: variant, isLoading: false));
        return;
      } catch (_) {
        emit(
          state.copyWith(errorMessage: 'Variant not found', isLoading: false),
        );
      }
    } else {
      emit(
        state.copyWith(
          errorMessage: 'No variants loaded - please load variants first.',
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onCreateProductVariant(
    CreateProductVariantEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await createProductVariant(
      CreateVariantParams(
        productId: event.productId,
        variant: event.variant,
        variantImage: event.variantImage,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (ProductVariantEntity variant) {
        final List<ProductVariantEntity> updatedVariants = [
          if (state.variants != null) ...state.variants!,
          variant,
        ];
        AppEventBus().fire(VariantCreatedEvent(variant));

        emit(
          state.copyWith(
            variants: updatedVariants,
            currentVariant: variant,
            isOperationLoading: false,
            isOperationSuccess: true,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateProductVariant(
    UpdateProductVariantEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await updateProductVariant(
      UpdateVariantParams(
        variantId: event.variantId,
        variant: event.variant,
        variantImage: event.variantImage,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (variant) {
        final updatedVariants = state.variants?.map((v) {
          return v.id == variant.id ? variant : v;
        }).toList();
        AppEventBus().fire(VariantUpdatedEvent(variant));
        return emit(
          state.copyWith(
            variants: updatedVariants,
            currentVariant: variant,
            isOperationLoading: false,
            isOperationSuccess: true,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteProductVariant(
    DeleteProductVariantEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await deleteProductVariant(
      DeleteVariantParams(
        productId: event.productId,
        variantId: event.variantId,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (success) {
        final updatedVariants = state.variants
            ?.where((variant) => variant.id != event.variantId)
            .toList();

        final shouldClearCurrent = state.currentVariant?.id == event.variantId;
        AppEventBus().fire(VariantDeletedEvent(event.variantId));
        return emit(
          state.copyWith(
            variants: updatedVariants,
            clearCurrentVariant: shouldClearCurrent,
            isOperationLoading: false,
            isOperationSuccess: true,
          ),
        );
      },
    );
  }

  Future _onBatchUpdateDiscounts(
    BatchUpdateDiscountsEvent event,
    Emitter emit,
  ) async {
    final currentVariants = state.variants;

    emit(state.copyWith(clearError: true, clearOperationSuccess: true));

    try {
      final Map<String, dynamic> variantsData = {
        'variants': event.variants
            .map(
              (v) => {
                'id': v.id,
                'product': v.productId,
                'price': v.price is MoneyEntity ? v.price.value : v.price,
                'discount_price': v.discountPrice != null
                    ? (v.discountPrice is MoneyEntity
                          ? v.discountPrice?.value
                          : v.discountPrice)
                    : null,
              },
            )
            .toList(),
        'is_discount_update': true,
      };

      final result = await manageProductVariants(
        ManageVariantsParams(id: event.productId, variantsData: variantsData),
      );

      return result.fold(
        (failure) {
          if (failure is ServerFailure) {
            emit(
              state.copyWith(
                errorMessage:
                    'Your session expired. Please save your work and log in again',
              ),
            );
            return;
          }

          emit(
            state.copyWith(
              errorMessage: _mapFailureToMessage(failure),
              variants: currentVariants,
            ),
          );
        },
        (success) {
          emit(
            state.copyWith(isOperationSuccess: true, variants: event.variants),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: "An unexpected error occurred: ${e.toString()}",
          variants: currentVariants,
        ),
      );
    }
  }

  Future<void> _onDistributeProductStock(
    DistributeProductStockEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final variantsData = {
      'variants': event.variants
          .map(
            (v) => {
              'id': v.id,
              'product': v.productId,
              'attributes': v.attributes,
              'sku': v.sku,
              'price': v.price is MoneyEntity ? v.price.value : v.price,
              'discount_price': v.discountPrice != null
                  ? (v.discountPrice is MoneyEntity
                        ? v.discountPrice?.value
                        : v.discountPrice)
                  : null,
              'stock': v.stock,
              'image_id': v.image?.id,
              'is_part_of_distribution': true,
            },
          )
          .toList(),
      'is_stock_distribution': true,
      'total_stock': event.totalStock,
    };

    final result = await distributeProductStockUseCase(
      DistributeStockParams(
        productId: event.productId,
        variantData: variantsData,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (success) {
        add(GetProductVariantsEvent(event.productId));
        emit(
          state.copyWith(isOperationLoading: false, isOperationSuccess: true),
        );
      },
    );
  }

  Future<void> _onUpdateVariantStock(
    UpdateVariantStockEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final variant = state.variants
        ?.where((v) => v.id == event.variantId)
        .firstOrNull;

    if (variant == null) {
      emit(
        state.copyWith(
          errorMessage: 'Variant not found',
          isOperationLoading: false,
        ),
      );
      return;
    }

    final updatedVariant = variant.copyWith(stock: event.newStock);
    final result = await updateProductVariant(
      UpdateVariantParams(variantId: event.variantId, variant: updatedVariant),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (updatedVariant) {
        final updatedVariants = state.variants?.map((v) {
          return v.id == updatedVariant.id ? updatedVariant : v;
        }).toList();
        AppEventBus().fire(VariantUpdatedEvent(updatedVariant));
        emit(
          state.copyWith(
            variants: updatedVariants,
            currentVariant: state.currentVariant?.id == event.variantId
                ? updatedVariant
                : state.currentVariant,
            isOperationLoading: false,
            isOperationSuccess: true,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateVariantPrice(
    UpdateVariantPriceEvent event,
    Emitter<ProductVariantState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final variant = state.variants
        ?.where((v) => v.id == event.variantId)
        .firstOrNull;

    if (variant == null) {
      emit(
        state.copyWith(
          errorMessage: 'Variant not found',
          isOperationLoading: false,
        ),
      );
      return;
    }

    final updatedVariant = variant.copyWith(
      price: MoneyEntity(value: event.price),
      discountPrice: event.discountPrice != null
          ? MoneyEntity(value: event.discountPrice!)
          : variant.discountPrice,
    );

    final result = await updateProductVariant(
      UpdateVariantParams(variantId: event.variantId, variant: updatedVariant),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (updatedVariant) {
        final updatedVariants = state.variants?.map((v) {
          return v.id == updatedVariant.id ? updatedVariant : v;
        }).toList();
        AppEventBus().fire(VariantUpdatedEvent(updatedVariant));
        emit(
          state.copyWith(
            variants: updatedVariants,
            currentVariant: state.currentVariant?.id == event.variantId
                ? updatedVariant
                : state.currentVariant,
            isOperationLoading: false,
            isOperationSuccess: true,
          ),
        );
      },
    );
  }

  void _onClearVariantError(
    ClearVariantErrorEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onClearOperationSuccess(
    ClearVariantOperationSuccessEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    if (state.isOperationSuccess) {
      emit(state.copyWith(clearOperationSuccess: true));
    }
  }

  void _onResetVariantState(
    ResetVariantStateEvent event,
    Emitter<ProductVariantState> emit,
  ) {
    emit(const ProductVariantState());
  }

  // ---HELPER METHODS---
  List<ProductVariantEntity> _generateAllVariantCombinations({
    required List<ProductVariationsEntity> variations,
    required String productId,
    required double basePrice,
    required int currentStock,
  }) {
    if (variations.isEmpty || variations.any((v) => v.values.isEmpty)) {
      return [];
    }

    List<Map<String, String>> combinations = [{}];
    for (var variation in variations) {
      List<Map<String, String>> newCombinations = [];
      for (var combination in combinations) {
        for (var value in variation.values) {
          newCombinations.add({...combination, variation.name: value});
        }
      }
      combinations = newCombinations;
    }

    final newVariants = combinations.map((attrs) {
      final variantId = _uuid.v4();
      return ProductVariantEntity(
        id: variantId,
        productId: productId,
        attributes: attrs,
        price: MoneyEntity(value: basePrice, currency: 'USD   '),
        stock: 0,
        sku: 'SKU-${variantId.substring(0, 8)}',
      );
    }).toList();
    return _distributeStock(variants: newVariants, totalStock: currentStock);
  }

  List<ProductVariantEntity> _distributeStock({
    required List<ProductVariantEntity> variants,
    required int totalStock,
  }) {
    if (variants.isEmpty || totalStock <= 0) return variants;
    final stockPerVariant = totalStock ~/ variants.length;
    final remainder = totalStock % variants.length;

    List<ProductVariantEntity> updatedVariants = [];

    for (int i = 0; i < variants.length; i++) {
      final stock = i < remainder ? stockPerVariant + 1 : stockPerVariant;
      updatedVariants.add(variants[i].copyWith(stock: stock));
    }
    return updatedVariants;
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server failure occurred';
      case CacheFailure _:
        return 'Cache failure occurred';
      case NetworkFailure _:
        return 'Network failure occurred. Please check your connection.';
      case ValidationFailure _:
        return 'Validation failure: ${(failure as ValidationFailure).message}';
      default:
        return 'Unexpected error occurred';
    }
  }
}
