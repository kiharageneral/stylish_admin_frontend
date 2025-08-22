import 'package:flutter/material.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/presentation/widgets/category_card.dart';

class CategoryGrid extends StatefulWidget {
  final List<CategoryEntity> categories;
  final bool hasMorePages;
  final Function? onLoadMore;

  const CategoryGrid({
    super.key,
    required this.categories,
    this.hasMorePages = false,
    this.onLoadMore,
  });

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  String _searchQuery = '';
  String? _filterByParent;
  bool? _filterByActive;
  bool _isLoadingMore = false;

  List<CategoryEntity> get _filteredCategories {
    return widget.categories.where((category) {
      // Filter by search
      if (_searchQuery.isNotEmpty &&
          !category.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Filter by parent
      if (_filterByParent != null && category.parent != _filterByParent) {
        return false;
      }

      // Filter by active status
      if (_filterByActive != null && category.isActive != _filterByActive) {
        return false;
      }

      return true;
    }).toList();
  }

  // Get the parent name for a given parent ID
  String? _getParentName(String? parentId) {
    if (parentId == null) return null;

    try {
      final parent = widget.categories.firstWhere((c) => c.id == parentId);
      return parent.name;
    } catch (e) {
      // Parent not found in the list
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = ResponsiveHelper.isMobile(context);
      final isTablet = ResponsiveHelper.isTablet(context);

      if (isMobile) {
        return Column(
          children: [
            Card(
              color: const Color(0xFF1A1A2E),
              child: ExpansionTile(
                title: const Text('Filters & Stats',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                collapsedBackgroundColor: const Color(0xFF1A1A2E),
                backgroundColor: const Color(0xFF1A1A2E),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildFilters(context, true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredCategories.isEmpty
                  ? _buildEmptyState()
                  : _buildGrid(context, true, false),
            ),
          ],
        );
      }

      return Column(
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: _buildFilters(context, false),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredCategories.isEmpty
                ? _buildEmptyState()
                : _buildGrid(context, false, isTablet),
          ),
        ],
      );
    });
  }

  Widget _buildFilters(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize
            .min, 
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search categories...',
              prefixIcon: const Icon(Icons.search,
                  color: Colors.white70, size: 20), 
              filled: true,
              fillColor: Colors.white.withAlpha((0.05 * 255).round()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              hintStyle: const TextStyle(
                  color: Colors.white70, fontSize: 14), 
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 6, horizontal: 12), 
              isDense: true, 
            ),
            style: const TextStyle(
                color: Colors.white, fontSize: 14), 
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),
          if (isMobile) ...[
            _buildStatusFilter(),
            const SizedBox(height: 8), 
            _buildParentFilter(),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildStatusFilter()),
                const SizedBox(width: 8),
                Expanded(child: _buildParentFilter()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<bool?>(
      value: _filterByActive,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(
            color: Colors.white70, fontSize: 14), 
        fillColor: Colors.white.withAlpha((0.05 * 255).round()),
        filled: true,
        isDense: true, 
      ),
      dropdownColor: const Color(0xFF16213E),
      style: const TextStyle(color: Colors.white),
      items: [
        const DropdownMenuItem<bool?>(
          value: null,
          child: Text('All Status', style: TextStyle(color: Colors.white)),
        ),
        const DropdownMenuItem<bool?>(
          value: true,
          child: Text('Active Only', style: TextStyle(color: Colors.white)),
        ),
        const DropdownMenuItem<bool?>(
          value: false,
          child: Text('Inactive Only', style: TextStyle(color: Colors.white)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _filterByActive = value;
        });
      },
    );
  }

  Widget _buildParentFilter() {
    final Map<String, String> parentMap = {};

    for (var category in widget.categories) {
      if (category.parent != null) {
        String? parentName = _getParentName(category.parent);
        if (parentName != null) {
          parentMap[category.parent!] = parentName;
        }
      }
    }

    return DropdownButtonFormField<String?>(
      value: _filterByParent,
      decoration: InputDecoration(
        labelText: 'Parent',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(color: Colors.white70),
        fillColor: Colors.white.withAlpha((0.05 * 255).round()),
        filled: true,
      ),
      dropdownColor: const Color(0xFF16213E),
      style: const TextStyle(color: Colors.white),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Categories', style: TextStyle(color: Colors.white)),
        ),
        ...parentMap.entries.map((entry) {
          return DropdownMenuItem<String?>(
            value: entry.key,
            child: Text(
              'In ${entry.value}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _filterByParent = value;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          const Text(
            'No categories found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfListIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          "End of list - No more categories",
          style: TextStyle(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, bool isMobile, bool isTablet) {

    int crossAxisCount = 4; 
    if (isMobile) {
      crossAxisCount = 1;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    double childAspectRatio = 1.0; 

    if (isMobile) {
      childAspectRatio = 0.9;
    } else if (isTablet) {
      childAspectRatio = 1.0;
    } else {
      childAspectRatio = 1.0;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (widget.hasMorePages &&
            widget.onLoadMore != null &&
            !_isLoadingMore &&
            scrollInfo.metrics.pixels >
                scrollInfo.metrics.maxScrollExtent - 500) {
          setState(() {
            _isLoadingMore = true;
          });
          widget.onLoadMore!();
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
              });
            }
          });
        }
        return false;
      },
      child: Stack(children: [
        GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _filteredCategories.length + 1, 
          itemBuilder: (context, index) {
            if (index >= _filteredCategories.length) {
              if (widget.hasMorePages) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                return _buildEndOfListIndicator();
              }
            }

            final category = _filteredCategories[index];
            return CategoryCard(
              category: category,
              index: index,
            );
          },
        ),
      ]),
    );
  }
}