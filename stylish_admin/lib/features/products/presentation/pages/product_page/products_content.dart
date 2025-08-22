import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_list/product_list_bloc.dart';
import 'package:stylish_admin/features/products/presentation/pages/components/product_actions_handler.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_page/product_pagination.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_page/products_empty_state.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_card.dart';

class ProductsContent extends StatefulWidget {
  final bool bulkMode;
  final int currentPage;
  final int totalPages;
  final Set<String> selectedProductIds;
  final Function(String, bool) onToggleSelection;
  final Function(int) onChangePage;

  const ProductsContent({
    super.key,
    required this.bulkMode,
    required this.currentPage,
    required this.totalPages,
    required this.selectedProductIds,
    required this.onToggleSelection,
    required this.onChangePage,
  });

  @override
  ProductsContentState createState() => ProductsContentState();
}

class ProductsContentState extends State<ProductsContent> {
  late ScrollController _scrollController;
  ScrollPosition? _lastKnownScrollPosition;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _lastKnownScrollPosition?.pixels ?? 0.0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void preserveScrollPosition() {
    // Save the current scroll position before any potential reset
    _lastKnownScrollPosition = _scrollController.position;

    // Restore the scroll position in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastKnownScrollPosition != null && mounted) {
        _scrollController.jumpTo(_lastKnownScrollPosition!.pixels);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocConsumer<ProductsListBloc, ProductListState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.accentRed,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading || state.isOperationLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state.paginatedProducts != null) {
            final products = state.paginatedProducts!.products;

            if (products.isEmpty) {
              return ProductsEmptyState();
            }

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.isMobile(context)
                          ? 1
                          : ResponsiveHelper.isTablet(context)
                              ? 2
                              : 3,
                      childAspectRatio: ResponsiveHelper.isTablet(context)
                          ? 0.8 
                          : 1,
                      crossAxisSpacing: AppTheme.spacingMedium,
                      mainAxisSpacing: AppTheme.spacingMedium,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        key: ValueKey(product.id),
                        product: product,
                        onEdit: () {
                          // Save scroll position before edit
                          preserveScrollPosition();
                          // ProductActionsHandler.navigateToEditPage(
                          //     context, product);
                        },
                        onDelete: () {
                          // Save scroll position before delete
                          preserveScrollPosition();
                          ProductActionsHandler.showDeleteConfirmation(
                              context, product);
                        },
                        isSelected: widget.bulkMode &&
                            widget.selectedProductIds.contains(product.id),
                        onSelect: widget.bulkMode
                            ? (selected) {
                                // Preserve scroll position during selection
                                preserveScrollPosition();
                                widget.onToggleSelection(product.id, selected);
                              }
                            : null,
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: ProductsPagination(
                    currentPage: widget.currentPage,
                    totalPages: widget.totalPages,
                    onChangePage: (page) {
                      widget.onChangePage(page);
                      // Reset scroll to top with a slight delay
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _scrollController.jumpTo(0);
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}