part of 'product_list_bloc.dart';

abstract class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object?> get props => [];
}

class GetPaginatedProductsEvent extends ProductListEvent {
  final int page;
  final int pageSize;
  final String? search;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final String? status;

  final StockStatus? stockStatus;
  final Map<String, dynamic>? extraParams;

  const GetPaginatedProductsEvent({
    required this.page,
    required this.pageSize,
    this.search,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.status,
    this.stockStatus,
    this.extraParams,
  });

  @override
  List<Object?> get props => [
    page,
    pageSize,
    search,
    categoryId,
    status,
    stockStatus,
    extraParams,
  ];
}

class SearchProductsEvent extends ProductListEvent {
  final String? searchQuery;
  final bool resetPage;
  final bool resetFilters;

  const SearchProductsEvent({
    this.searchQuery,
    this.resetPage = false,
    this.resetFilters = false,
  });

  @override
  List<Object?> get props => [searchQuery, resetPage, resetFilters];
}

class SetLoadingEvent extends ProductListEvent {
  final bool isLoading;

  const SetLoadingEvent(this.isLoading);
  @override
  List<Object> get props => [isLoading];
}

class SetCachedProductsEvent extends ProductListEvent {
  final List<ProductEntity> products;
  final int page;
  final int totalCount;

  const SetCachedProductsEvent({
    required this.products,
    required this.page,
    required this.totalCount,
  });
}

class ClearFiltersEvent extends ProductListEvent {
  @override
  List<Object?> get props => [];
}

class LoadMoreProductsEvent extends ProductListEvent {
  final int page;
  final int pageSize;

  const LoadMoreProductsEvent({required this.page, required this.pageSize});

  @override
  List<Object> get props => [page, pageSize];
}

class BulkDeleteProductsEvent extends ProductListEvent {
  final List<String> productIds;

  const BulkDeleteProductsEvent({required this.productIds});
  @override
  List<Object?> get props => [productIds];
}

class GetProductCategoriesEvent extends ProductListEvent {}

class GetProductFiltersEvent extends ProductListEvent {}

class ToggleProductStatusEvent extends ProductListEvent {
  final String id;
  const ToggleProductStatusEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

class ClearOperationSuccessEvent extends ProductListEvent{}

class ClearProductErrorEvent extends ProductListEvent {}
class ResetProductListEvent extends ProductListEvent{}
class ProductDeletedEvent extends ProductListEvent {
  final String productId;

  const ProductDeletedEvent({required this.productId});

  @override  
  List<Object?> get props => [productId];
  
}
