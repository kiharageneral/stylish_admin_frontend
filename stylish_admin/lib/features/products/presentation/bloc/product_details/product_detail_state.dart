part of 'product_details_bloc.dart';

class ProductDetailState extends Equatable {
  final ProductEntity? product;
  final String? errorMessage;
  final bool isLoading;
  final bool isOperationLoading;
  final bool isOperationSuccess;
  final bool isDeleted;

  const ProductDetailState({
    this.product,
    this.errorMessage,
    this.isLoading = false,
    this.isOperationLoading = false,
    this.isOperationSuccess = false,
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => [
    product,
    errorMessage,
    isLoading,
    isOperationLoading,
    isOperationSuccess,
    isDeleted,
  ];

  ProductDetailState copyWith({
    ProductEntity? product, 
    String? errorMessage, 
    bool? isLoading, 
    bool? isOperationLoading, 
    bool? isOperationSuccess, 
    bool? isDeleted, 
    bool clearError = false, 
    bool clearOperationSuccess = false, 
    bool clearProduct = false,
  }) {
    return ProductDetailState(
      product:  clearProduct ? null : (product ?? this.product), 
      errorMessage: clearError ? null: (errorMessage ?? this.errorMessage), 
      isLoading: isLoading ?? this.isLoading, 
      isOperationLoading:  isOperationLoading ?? this.isOperationLoading, 
      isOperationSuccess: clearOperationSuccess?false:(isOperationSuccess ?? this.isOperationSuccess), 
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class ProductDetailInitial extends ProductDetailState{}
