
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class ProductsSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String? initialSearchQuery;
  final bool isSearching;

  const ProductsSearchBar({
    super.key,
    required this.onSearch,
    this.initialSearchQuery,
    this.isSearching = false,
  });

  @override
  State<ProductsSearchBar> createState() => _ProductsSearchBarState();
}

class _ProductsSearchBarState extends State<ProductsSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }
  }

  @override
  void didUpdateWidget(ProductsSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery != _searchController.text) {
      _searchController.text = widget.initialSearchQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _performSearch() {
    final searchQuery = _searchController.text.trim();
    // Hide keyboard
    FocusScope.of(context).unfocus();
    widget.onSearch(searchQuery);
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearch('');
  }

 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTheme.bodyMedium(),
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: AppTheme.bodyMedium()
                    .copyWith(color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  borderSide:
                      BorderSide(color: AppTheme.primaryLight, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.backgroundMedium,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          ElevatedButton(
            onPressed: _performSearch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              backgroundColor: AppTheme.primaryLight,
            ),
            child: widget.isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Search'),
          ),
        ],
      ),
    );
  }
}
