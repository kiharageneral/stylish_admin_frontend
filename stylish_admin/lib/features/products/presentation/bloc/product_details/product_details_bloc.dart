import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/event_bus/app_event_bus.dart';
import 'package:stylish_admin/features/products/domain/entities/money_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/usecases/product_usecase.dart';
part 'product_detail_event.dart';
part 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final GetProductByIdUsecase getProductById;
  final CreateProductUsecase createProduct;
  final UpdateProductUsecase updateProduct;
  final DeleteProductUsecase deleteProduct;
  final UpdateProductPrice updateProductPrice;
  final UpdateProductStock updateProductStock;
  final UpdateProductProfitMargin updateProductProfitMargin;
  final ManagProductImages managProductImages;
  final DeleteProductImageUsecase deleteProductImage;

  ProductDetailBloc({
    required this.getProductById,
    required this.createProduct,
    required this.updateProduct,
    required this.deleteProduct,
    required this.updateProductPrice,
    required this.updateProductStock,
    required this.updateProductProfitMargin,
    required this.managProductImages,
    required this.deleteProductImage,
  }) : super(ProductDetailInitial()) {
    on<GetProductByIdEvent>(_onGetProductById);
    on<CreateProductEvent>(_onCreateProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<UpdateProductStockEvent>(_onUpdateProductStock);
    on<UpdateProductPriceEvent>(_onUpdateProductPrice);
    on<UpdateProductProfitMarginEvent>(_onUpdateProductProfitMargin);
    on<ManageProductImagesEvent>(_onManageProductImages);
    on<DeleteProductImageEvent>(_onDeleteProductImage);
    on<ClearProductDetailErrorEvent>(_onClearProductError);
    on<ClearProductDetailOperationSuccessEvent>(_onClearOperationSuccess);
    on<ResetProductDetailStateEvent>(_onResetProductDetailState);
  }

  Future<void> _onGetProductById(
    GetProductByIdEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await getProductById(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        ),
      ),
      (product) => emit(state.copyWith(product: product, isLoading: false)),
    );
  }

  Future<void> _onCreateProduct(
    CreateProductEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );
    final result = await createProduct(
      CreateProductParams(product: event.product, images: event.images),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (product) {
        AppEventBus().fire(ProductCreatedEvent(product));
        emit(
          state.copyWith(
            product: product,
            isOperationLoading: false,
            isOperationSuccess: true,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateProduct(UpdateProductEvent event, Emitter emit) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    try {
      final result = await updateProduct(
        UpdateProductParams(
          id: event.id,
          product: event.product,
          newImages: event.newImages,
        ),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isOperationLoading: false,
          ),
        ),
        (product) {
          AppEventBus().fire(ProductUpdatedEvent(product));
          emit(
            state.copyWith(
              product: product,
              isOperationSuccess: true,
              isOperationLoading: false,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Unexpected error: $e',
          isOperationLoading: false,
        ),
      );
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );
    final result = await deleteProduct(event.productId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (success) {
        AppEventBus().fire(ProductRemovedEvent(event.productId));
        emit(
          state.copyWith(
            product: null,
            isOperationLoading: false,
            isOperationSuccess: true,
            isDeleted: true,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateProductStock(
    UpdateProductStockEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await updateProductStock(
      UpdateStockParams(
        id: event.id,
        newStock: event.newStock,
        reason: event.reason ?? 'Stock update',
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
        if (state.product?.id == event.id) {
          final updatedProduct = state.product!.copyWith(stock: event.newStock);
          AppEventBus().fire(ProductUpdatedEvent(updatedProduct));
          emit(
            state.copyWith(
              product: updatedProduct,
              isOperationLoading: false,
              isOperationSuccess: true,
            ),
          );
        } else {
          emit(
            state.copyWith(isOperationLoading: false, isOperationSuccess: true),
          );
        }
      },
    );
  }

  Future<void> _onUpdateProductPrice(
    UpdateProductPriceEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await updateProductPrice(
      UpdatePriceParams(
        id: event.id,
        price: event.price,
        discountPrice: event.discountPrice,
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
        if (state.product?.id == event.id) {
          final updatedProduct = state.product!.copyWith(
            price: MoneyEntity(value: event.price),
            discountPrice: event.discountPrice != null
                ? MoneyEntity(value: event.discountPrice!)
                : state.product!.discountPrice,
          );
          AppEventBus().fire(ProductUpdatedEvent(updatedProduct));
          emit(
            state.copyWith(
              product: updatedProduct,
              isOperationLoading: false,
              isOperationSuccess: true,
            ),
          );
        } else {
          emit(
            state.copyWith(isOperationLoading: false, isOperationSuccess: true),
          );
        }
      },
    );
  }

  Future<void> _onUpdateProductProfitMargin(
    UpdateProductProfitMarginEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await updateProductProfitMargin(
      UpdateProfitMarginParams(
        id: event.id,
        cost: event.cost,
        price: event.price,
        profitMargin: event.profitMargin,
        discountPrice: event.discountPrice,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (updatedProduct) {
         AppEventBus().fire(ProductUpdatedEvent(updatedProduct));
        emit(
          state.copyWith(
            product: updatedProduct,
            isOperationLoading: false,
            isOperationSuccess: true,
          ),
        );
      },
    );
  }

  Future<void> _onManageProductImages(
    ManageProductImagesEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await managProductImages(
      ManageImagesParams(
        id: event.id,
        images: event.images,
        isPrimaryList: event.isPrimaryList,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (images) {
        if (state.product?.id == event.id) {
          final updatedProduct = state.product!.copyWith(images: images);
          emit(
            state.copyWith(
              product: updatedProduct,
              isOperationLoading: false,
              isOperationSuccess: true,
            ),
          );
        } else {
          emit(
            state.copyWith(isOperationLoading: false, isOperationSuccess: true),
          );
        }
      },
    );
  }

  Future<void> _onDeleteProductImage(
    DeleteProductImageEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await deleteProductImage(
      DeleteImageParams(productId: event.productId, imageId: event.imageId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (success) => emit(
        state.copyWith(isOperationLoading: false, isOperationSuccess: true),
      ),
    );
  }

  void _onClearProductError(
    ClearProductDetailErrorEvent event,
    Emitter<ProductDetailState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onClearOperationSuccess(
    ClearProductDetailOperationSuccessEvent event,
    Emitter<ProductDetailState> emit,
  ) {
    if (state.isOperationSuccess) {
      emit(state.copyWith(clearOperationSuccess: true));
    }
  }

  void _onResetProductDetailState(
    ResetProductDetailStateEvent event,
    Emitter<ProductDetailState> emit,
  ) {
    emit(ProductDetailState());
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
