
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_list/product_list_bloc.dart';

class ProductFilterDialog extends StatefulWidget {
  final String? initialCategory;
  final String? initialStatus;
  final StockStatus? initialStockStatus;
  final double? initialMinPrice;
  final double? initialMaxPrice;

  const ProductFilterDialog({
    super.key,
    this.initialCategory,
    this.initialStatus,
    this.initialStockStatus,
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  @override
  State<ProductFilterDialog> createState() => _ProductFilterDialogState();
}

class _ProductFilterDialogState extends State<ProductFilterDialog> {
  late String? _selectedCategory;
  late String? _selectedStatus;
  late StockStatus? _selectedStockStatus;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductsListBloc>().state;

    _selectedCategory = state.currentCategoryId ?? widget.initialCategory;
    _selectedStatus = state.currentStatus ?? widget.initialStatus;
    _selectedStockStatus =
        state.currentStockStatus ?? widget.initialStockStatus;
    _priceRange = RangeValues(
        state.currentMinPrice ?? widget.initialMinPrice ?? 0,
        state.currentMaxPrice ?? widget.initialMaxPrice ?? 1000);
  }

  void _applyFilters() {
    // Trigger the filter event in the Bloc
    context.read<ProductsListBloc>().add(
          GetPaginatedProductsEvent(
            page: 1, // Reset to first page
            pageSize: 20,
            categoryId: _selectedCategory,
            status: _selectedStatus,
            stockStatus: _selectedStockStatus,
            minPrice: _priceRange.start,
            maxPrice: _priceRange.end,
          ),
        );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    // Reset all local filters
    setState(() {
      _selectedCategory = null;
      _selectedStatus = null;
      _selectedStockStatus = null;
      _priceRange = RangeValues(0, 1000);
    });

    context.read<ProductsListBloc>().add(ClearFiltersEvent());

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsListBloc, ProductListState>(
      builder: (context, state) {
        if (state.filters == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return AlertDialog(
          title: Text('Filter Products', style: AppTheme.headingMedium()),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacingMedium),
                // Category Dropdown
                _buildCategoryDropdown(state.categories ?? []),
                const SizedBox(height: AppTheme.spacingMedium),
                // Status Dropdown
                _buildStatusDropdown(state.filters!.statusOptions),
                const SizedBox(height: AppTheme.spacingMedium),
                // Stock Status Dropdown
                _buildStockStatusDropdown(state.filters!.stockStatusOptions),
                const SizedBox(height: AppTheme.spacingMedium),
                // Price Range Slider
                _buildPriceRangeSlider(state.filters!.minPrice ?? 0,
                    state.filters!.maxPrice ?? 1000),
                const SizedBox(height: AppTheme.spacingMedium),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _clearFilters,
              child: Text('Clear Filters'),
            ),
            ElevatedButton(
              onPressed: _applyFilters,
              child: Text('Apply Filters'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDropdown(List<ProductCategory> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('All Categories'),
        ),
        ...categories
            .map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ))
            ,
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildStatusDropdown(List<String> statusOptions) {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('All Statuses'),
        ),
        ...statusOptions
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
            ,
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildStockStatusDropdown(List<StockStatus> stockStatusOptions) {
    return DropdownButtonFormField<StockStatus>(
      value: _selectedStockStatus,
      decoration: InputDecoration(
        labelText: 'Stock Status',
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('All Stock Statuses'),
        ),
        ...stockStatusOptions
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                ))
            ,
      ],
      onChanged: (value) {
        setState(() {
          _selectedStockStatus = value;
        });
      },
    );
  }

  Widget _buildPriceRangeSlider(double minPrice, double maxPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Range', style: AppTheme.bodyLarge()),
        RangeSlider(
          values: _priceRange,
          min: minPrice,
          max: maxPrice,
          divisions: 100,
          labels: RangeLabels(
            '\$${_priceRange.start.toStringAsFixed(2)}',
            '\$${_priceRange.end.toStringAsFixed(2)}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
      ],
    );
  }
}
