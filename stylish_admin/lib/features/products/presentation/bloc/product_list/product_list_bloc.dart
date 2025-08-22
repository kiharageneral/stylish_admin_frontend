import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/event_bus/app_event_bus.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/products/domain/entities/paginated_products_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/product_filters_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/domain/usecases/get_product_filters_usecase.dart';
import 'package:stylish_admin/features/products/domain/usecases/product_usecase.dart';
part 'product_list_event.dart';
part 'product_list_state.dart';

class ProductsListBloc extends Bloc<ProductListEvent, ProductListState> {
  final GetProductsPaginated getProductsPaginated;
  final BulkDeleteUsecase bulkDeleteProducts;
  final GetProductCategoriesUsecase getProductCategories;
  final GetProductFiltersUsecase getProductFilters;
  final ToggleProductStatus toggleProductStatus;

  String? _currentSearchQuery;
  String? _currentCategoryId;
  String? _currentStatus;
  StockStatus? _currentStockStatus;
  int _currentPage = 1;
  final int _pageSize = 20;

  late final StreamSubscription<AppEvent> _subscription;

  ProductsListBloc({
    required this.getProductsPaginated,
    required this.bulkDeleteProducts,
    required this.getProductCategories,
    required this.getProductFilters,
    required this.toggleProductStatus,
  }) : super(ProductListInitial()) {
    on<GetPaginatedProductsEvent>(_onGetPaginatedProducts);
    on<BulkDeleteProductsEvent>(_onBulkDeleteProducts);
    on<GetProductCategoriesEvent>(_onGetProductCategories);
    on<GetProductFiltersEvent>(_onGetProductFilters);
    on<ToggleProductStatusEvent>(_onToggleProductStatus);
    on<LoadMoreProductsEvent>(_onLoadMoreProducts);
    on<ClearProductErrorEvent>(_onClearProductError);
    on<ClearOperationSuccessEvent>(_onClearOperationSuccess);
    on<ResetProductListEvent>(_onResetProductListState);
    on<ProductDeletedEvent>(_onProductDeleted);
    on<SearchProductsEvent>(_onSearchProducts);
    on<SetLoadingEvent>(_onSetLoading);
    on<ClearFiltersEvent>(_onClearFilters);
    _subscription = AppEventBus().events.listen((event) {
      if (event is ProductCreatedEvent ||
          event is ProductUpdatedEvent ||
          event is VariantCreatedEvent ||
          event is VariantUpdatedEvent ||
          event is VariantDeletedEvent) {
        refreshProductList(bypassCache: true);
      } else if (event is ProductRemovedEvent) {
        add(ProductDeletedEvent(productId: event.productId));
      }
    });
  }

  void refreshProductList({bool bypassCache = true}) {
    add(
      GetPaginatedProductsEvent(
        page: 1,
        pageSize: _pageSize,
        search: _currentSearchQuery,
        categoryId: _currentCategoryId,
        status: _currentStatus,
        stockStatus: _currentStockStatus,
        extraParams: bypassCache ? {"bypassCache": true} : null,
      ),
    );
  }

  void _onSetLoading(SetLoadingEvent event, Emitter<ProductListState> emit) {
    emit(state.copyWith(isLoading: event.isLoading));
  }

  void _onProductDeleted(
    ProductDeletedEvent event,
    Emitter<ProductListState> emit,
  ) {
    if (state.paginatedProducts != null) {
      final updatedProducts = state.paginatedProducts!.products
          .where((product) => product.id != event.productId)
          .toList();

      final updatedPaginatedProducts = state.paginatedProducts!.copyWith(
        products: updatedProducts,
        totalCount: state.paginatedProducts!.totalCount - 1,
      );

      emit(
        state.copyWith(
          paginatedProducts: updatedPaginatedProducts,
          isOperationSuccess: true,
        ),
      );
    }
  }

  Future<void> _onGetPaginatedProducts(
    GetPaginatedProductsEvent event,
    Emitter<ProductListState> emit,
  ) async {
    if (state.isLoading) return;
    try {
      // Store current filter values in the state
      emit(
        state.copyWith(
          currentSearchQuery: event.search,
          currentCategoryId: event.categoryId,
          currentStatus: event.status,
          currentStockStatus: event.stockStatus,
          currentPage: event.page,
          pageSize: event.pageSize,
          currentMinPrice: event.minPrice,
          currentMaxPrice: event.maxPrice,
          isLoading: true,
          clearError: true,
          paginatedProducts: event.search != state.currentSearchQuery
              ? null
              : state.paginatedProducts,
        ),
      );

      final params = ProductsFilterParams(
        page: event.page,
        pageSize: event.pageSize,
        search: event.search,
        status: event.status,
        stockStatus: event.stockStatus,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        categoryId: event.categoryId,
        extraParams: {
          ...event.extraParams ?? {},
          "preloadImages": false,
          'loadBasicInfo': true,
          'include_all_images': false,
          'request_timestamp': DateTime.now().microsecondsSinceEpoch,
          'validate_category': true,
          'debug_search': event.search != null
              ? "search_term_${event.search}"
              : null,
        },
      );

      final result = await getProductsPaginated(params);

      result.fold(
        (failure) => emit(
          state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isLoading: false,
          ),
        ),
        (paginatedProducts) {
          if (paginatedProducts.products.isEmpty &&
              event.search != null &&
              event.search!.isNotEmpty) {
            emit(
              state.copyWith(
                paginatedProducts: PaginatedProductsEntity(
                  products: [],
                  totalCount: 0,
                  currentPage: event.page,
                  totalPages: 1,
                  pageSize: event.pageSize,
                  hasNextPage: false,
                  hasPreviousPage: false,
                ),
                errorMessage:
                    'No products found matching "${event.search}". Try different search terms.',
                isLoading: false,
              ),
            );
          } else {
            emit(
              state.copyWith(
                paginatedProducts: paginatedProducts,
                isLoading: false,
                clearError: true,
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage:
              'Unexpected error during product retrieval : ${e.toString()}',
          isLoading: false,
        ),
      );
    }
  }

  void _onClearFilters(
    ClearFiltersEvent event,
    Emitter<ProductListState> emit,
  ) {
    // Reset all filter state variables
    _currentSearchQuery = null;
    _currentCategoryId = null;
    _currentStatus = null;
    _currentStockStatus = null;
    _currentPage = 1;

    // Update state with cleared filters
    emit(
      state.copyWith(
        currentSearchQuery: null,
        currentCategoryId: null,
        currentStatus: null,
        currentStockStatus: null,
        currentMaxPrice: null,
        currentMinPrice: null,
        currentPage: 1,
        clearError: true,
      ),
    );

    add(GetPaginatedProductsEvent(page: 1, pageSize: _pageSize));
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProductsEvent event,
    Emitter<ProductListState> emit,
  ) async {
    try {
      final params = ProductsFilterParams(
        page: event.page,
        pageSize: event.pageSize,
        search: _currentSearchQuery,
        status: _currentStatus,
        categoryId: _currentCategoryId,
        stockStatus: _currentStockStatus,
        extraParams: {"preloadImages": false, "loadBasicInfo": true},
      );

      final result = await getProductsPaginated(params);

      result.fold(
        (failure) =>
            emit(state.copyWith(errorMessage: _mapFailureToMessage(failure))),
        (newPage) {
          final existingProducts = state.paginatedProducts?.products ?? [];
          final mergedProducts = [...existingProducts, ...newPage.products];

          final updatedPaginatedProducts =
              state.paginatedProducts?.copyWith(
                products: mergedProducts,
                totalCount: newPage.totalCount,
                currentPage: newPage.currentPage,
                totalPages: newPage.totalPages,
                hasNextPage: newPage.hasNextPage,
                hasPreviousPage: newPage.hasPreviousPage,
              ) ??
              newPage;

          emit(state.copyWith(paginatedProducts: updatedPaginatedProducts));
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to load more products ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSearchProducts(
    SearchProductsEvent event,
    Emitter<ProductListState> emit,
  ) async {
    // show loading state
    emit(state.copyWith(isLoading: true, clearError: true));

    // Clean up the search query
    final searchQuery = (event.searchQuery?.trim() == '')
        ? null
        : event.searchQuery?.trim();

    try {
      final useCurrentStockStatus = event.resetPage
          ? null
          : state.currentStockStatus;
      final useCurrentCategoryId = event.resetPage
          ? null
          : state.currentCategoryId;
      final useCurrentStatus = event.resetPage ? null : state.currentStatus;
      final useCurrentMinPrice = event.resetPage ? null : state.currentMinPrice;
      final useCurrentMaxPrice = event.resetPage ? null : state.currentMaxPrice;

      final params = ProductsFilterParams(
        page: 1,
        pageSize: state.pageSize,
        search: searchQuery,
        categoryId: useCurrentCategoryId,
        status: useCurrentStatus,
        stockStatus: useCurrentStockStatus,
        minPrice: useCurrentMinPrice,
        maxPrice: useCurrentMaxPrice,
        extraParams: {
          "preloadImages": false,
          "loadBasicInfo": true,
          "bypassCache": true,
          "request_timestamp": DateTime.now().microsecondsSinceEpoch,
          "debug_search": searchQuery != null
              ? "search_term_$searchQuery"
              : null,
        },
      );

      final result = await getProductsPaginated(params);

      result.fold(
        (failure) => emit(
          state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isLoading: false,
            currentSearchQuery: searchQuery,
            currentPage: 1,
          ),
        ),
        (paginatedProducts) {
          if (paginatedProducts.products.isEmpty &&
              searchQuery != null &&
              searchQuery.isNotEmpty) {
            emit(
              state.copyWith(
                paginatedProducts: PaginatedProductsEntity(
                  products: [],
                  totalCount: 0,
                  currentPage: 1,
                  totalPages: 1,
                  pageSize: params.pageSize,
                  hasNextPage: false,
                  hasPreviousPage: false,
                ),
                errorMessage:
                    'No products found matching "$searchQuery". Try different search terms',
                isLoading: false,
                currentSearchQuery: searchQuery,
                currentPage: 1,
              ),
            );
          } else {
            emit(
              state.copyWith(
                paginatedProducts: paginatedProducts,
                isLoading: false,
                clearError: true,
                currentSearchQuery: searchQuery,
                currentPage: 1,
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Search error: ${e.toString()}',
          isLoading: false,
          currentSearchQuery: searchQuery,
        ),
      );
    }
  }

  Future<void> _onBulkDeleteProducts(
    BulkDeleteProductsEvent event,
    Emitter<ProductListState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await bulkDeleteProducts(event.productIds);

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (succcess) {
        final currentProducts = state.paginatedProducts?.products ?? [];
        final currentCount = state.paginatedProducts?.totalCount ?? 0;

        final updatedProducts = currentProducts
            .where((p) => !event.productIds.contains(p.id))
            .toList();
        final removedCount = currentProducts.length - updatedProducts.length;

        final updatedPaginatedProducts = state.paginatedProducts?.copyWith(
          products: updatedProducts,
          totalCount: (currentCount - removedCount)
              .clamp(0, double.infinity)
              .toInt(),
        );
        return emit(
          state.copyWith(
            paginatedProducts: updatedPaginatedProducts,
            isOperationLoading: false,
            isOperationSuccess: true,
          ),
        );
      },
    );
  }

  Future<void> _onGetProductCategories(
    GetProductCategoriesEvent event,
    Emitter<ProductListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await getProductCategories(NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        ),
      ),
      (categories) =>
          emit(state.copyWith(categories: categories, isLoading: false)),
    );
  }

  Future<void> _onGetProductFilters(
    GetProductFiltersEvent event,
    Emitter<ProductListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await getProductFilters(NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        ),
      ),
      (filters) {
        final categories = filters.categories
            .map(
              (category) =>
                  ProductCategory(id: category.id, name: category.name),
            )
            .toList();
        emit(
          state.copyWith(
            filters: filters,
            categories: categories,
            isLoading: false,
          ),
        );
      },
    );
  }

  Future<void> _onToggleProductStatus(
    ToggleProductStatusEvent event,
    Emitter<ProductListState> emit,
  ) async {
    emit(
      state.copyWith(
        isOperationLoading: true,
        clearError: true,
        clearOperationSuccess: true,
      ),
    );

    final result = await toggleProductStatus(event.id);

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isOperationLoading: false,
        ),
      ),
      (success) {
        add(
          GetPaginatedProductsEvent(
            page: _currentPage,
            pageSize: _pageSize,
            search: _currentSearchQuery,
            categoryId: _currentCategoryId,
            status: _currentStatus,
            stockStatus: _currentStockStatus,
            extraParams: {"bypassCache": true},
          ),
        );

        emit(
          state.copyWith(isOperationSuccess: true, isOperationLoading: false),
        );
      },
    );
  }

  void _onClearProductError(
    ClearProductErrorEvent event,
    Emitter<ProductListState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onClearOperationSuccess(
    ClearOperationSuccessEvent event,
    Emitter<ProductListState> emit,
  ) {
    if (state.isOperationSuccess) {
      emit(state.copyWith(clearOperationSuccess: true));
    }
  }

  void _onResetProductListState(
    ResetProductListEvent event,
    Emitter<ProductListState> emit,
  ) {
    emit(ProductListState());
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
