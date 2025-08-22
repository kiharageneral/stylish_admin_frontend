part of 'product_list_bloc.dart';


class ProductListState extends Equatable {
  final PaginatedProductsEntity? paginatedProducts;
  final List<ProductCategory>? categories;
  final ProductFiltersEntity? filters;
  final String? errorMessage;
  final bool isLoading;
  final bool isOperationLoading;
  final bool isOperationSuccess;

  // Fields to maintain filter context
  final String? currentSearchQuery;
  final String? currentCategoryId;
  final String? currentStatus;
  final StockStatus? currentStockStatus;
  final double? currentMinPrice;
  final double? currentMaxPrice;
  final int currentPage;
  final int pageSize;

  const ProductListState({
    this.paginatedProducts,
    this.categories,
    this.filters,
    this.errorMessage,
    this.isLoading = false,
    this.isOperationLoading = false,
    this.isOperationSuccess = false,
    this.currentSearchQuery,
    this.currentCategoryId,
    this.currentStatus,
    this.currentStockStatus,
    this.currentMinPrice,
    this.currentMaxPrice,
    this.currentPage = 1,
    this.pageSize = 20,
  });

  @override  
  List<Object?> get props => [
    paginatedProducts, categories, filters, errorMessage, isLoading, isOperationLoading, isOperationSuccess, currentSearchQuery, currentCategoryId, currentStatus, currentStockStatus, currentMaxPrice, currentMinPrice, currentPage, pageSize
  ];

  ProductListState copyWith({
    PaginatedProductsEntity? paginatedProducts,
    List<ProductCategory>? categories, 
    ProductFiltersEntity? filters, 
    String? errorMessage, 
    bool? isLoading, 
    bool? isOperationLoading, 
    bool? isOperationSuccess, 
    String? currentSearchQuery, 
    String? currentCategoryId, 
    String? currentStatus, 
    StockStatus? currentStockStatus, 
    double? currentMinPrice, 
    double? currentMaxPrice, 
    int? currentPage, 
    int? pageSize, 
    bool clearError = false, 
    bool clearOperationSuccess = false
  }) {
    return ProductListState(
        paginatedProducts: paginatedProducts ?? this.paginatedProducts, 
        categories:  categories ?? this.categories, 
        filters:  filters ?? this.filters, 
        errorMessage:  clearError ?null: (errorMessage ?? this.errorMessage), 
        isLoading: isLoading ?? this.isLoading, 
        isOperationLoading: isOperationLoading ?? this.isOperationLoading, 
        isOperationSuccess: clearOperationSuccess ?false : (isOperationSuccess ?? this.isOperationSuccess), 
        currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery, 
        currentCategoryId: currentCategoryId ?? this.currentCategoryId, 
        currentStatus: currentStatus ?? this.currentStatus, 
        currentStockStatus: currentStockStatus ?? this.currentStockStatus, 
        currentMinPrice: currentMinPrice ?? this.currentMinPrice, 
        currentMaxPrice:  currentMaxPrice??this.currentMaxPrice, 
        currentPage: currentPage ?? this.currentPage, 
        pageSize:  pageSize ?? this.pageSize,
    );
  }
}

class ProductListInitial extends ProductListState{}
