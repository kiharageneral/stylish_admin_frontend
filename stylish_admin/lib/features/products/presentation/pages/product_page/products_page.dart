
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_list/product_list_bloc.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_page/product_filter_dialog.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_page/product_search_bar.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_page/products_content.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_page/products_header.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  // Core state that needs to be managed at the page level
  final Set<String> _selectedProductIds = {};
  bool _bulkMode = false;
  String? _searchQuery;
  final GlobalKey<ProductsContentState> _productsContentKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Load initial products
    _loadProducts();

    // Load filters
    context.read<ProductsListBloc>().add(GetProductFiltersEvent());
  }


  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.trim().isEmpty ? null : query.trim();
      _selectedProductIds.clear(); 
    });

    final bloc = context.read<ProductsListBloc>();
    bloc.add(SearchProductsEvent(
      searchQuery: _searchQuery,
      resetPage: true,
    ));
  }

  void _loadProducts(
      {int page = 1, int pageSize = 20, bool bypassCache = false}) {
    final extraParams = {
      "preloadImages": false,
      "loadBasicInfo": true,
      if (bypassCache) "bypassCache": true,
    };

    context.read<ProductsListBloc>().add(GetPaginatedProductsEvent(
          page: page,
          pageSize: pageSize,
          search: _searchQuery,
          extraParams: extraParams,
        ));
  }

  void _toggleBulkMode() {
    setState(() {
      _bulkMode = !_bulkMode;
      if (!_bulkMode) {
        _selectedProductIds.clear();
      }
    });
  }

  void _toggleProductSelection(String productId, bool isSelected) {
    // Preserve scroll position when selecting a product
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        if (isSelected) {
          _selectedProductIds.add(productId);
        } else {
          _selectedProductIds.remove(productId);
        }
      });

      // Use the key to access the scroll position preservation method
      _productsContentKey.currentState?.preserveScrollPosition();
    });
  }

  void _bulkDeleteProducts() {
    if (_selectedProductIds.isEmpty) return;

    context
        .read<ProductsListBloc>()
        .add(BulkDeleteProductsEvent(productIds: _selectedProductIds.toList()));
    _toggleBulkMode();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const ProductFilterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductsListBloc, ProductListState>(
          listenWhen: (previous, current) =>
              previous.isOperationSuccess != current.isOperationSuccess ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.isOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Operation completed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              context
                  .read<ProductsListBloc>()
                  .add(ClearOperationSuccessEvent());
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child:  BlocBuilder<ProductsListBloc, ProductListState>(
          builder: (context, state) {
            return Column(
              children: [
                ProductsHeader(
                  bulkMode: _bulkMode,
                  selectedCount: _selectedProductIds.length,
                  toggleBulkMode: _toggleBulkMode,
                  bulkDelete: _bulkDeleteProducts,
                  onShowFilters: _showFilterDialog,
                ),
                ProductsSearchBar(
                  onSearch: _onSearch,
                  initialSearchQuery: _searchQuery,
                  isSearching: state.isLoading,
                ),
                state.isLoading && state.paginatedProducts == null
                    ? const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : ProductsContent(
                        key: _productsContentKey,
                        bulkMode: _bulkMode,
                        currentPage: state.paginatedProducts?.currentPage ?? 1,
                        totalPages: _calculateTotalPages(state),
                        selectedProductIds: _selectedProductIds,
                        onToggleSelection: _toggleProductSelection,
                        onChangePage: (page) => _loadProducts(page: page),
                      ),
              ],
            );
          },
        ),
    );
  }

  int _calculateTotalPages(ProductListState state) {
    final totalCount = state.paginatedProducts?.totalCount ?? 0;
    final pageSize = 20; 
    return (totalCount / pageSize).ceil();
  }
}
