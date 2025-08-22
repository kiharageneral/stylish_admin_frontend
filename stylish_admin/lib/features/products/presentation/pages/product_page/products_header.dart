
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_list/product_list_bloc.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_forms/product_create_page.dart';

class ProductsHeader extends StatelessWidget {
  final bool bulkMode;
  final int selectedCount;
  final VoidCallback toggleBulkMode;
  final VoidCallback bulkDelete;
  final VoidCallback onShowFilters;

  const ProductsHeader({
    super.key,
    required this.bulkMode,
    required this.selectedCount,
    required this.toggleBulkMode,
    required this.bulkDelete,
    required this.onShowFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: _buildHeaderContent(context),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    // Determine responsive layout based on screen size
    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileLayout(context);
    } else if (ResponsiveHelper.isTablet(context)) {
      return _buildTabletLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Products',
          style: AppTheme.headingMedium().copyWith(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              forMobile: 20,
              forTablet: 24,
              forDesktop: 28,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Wrap(
          spacing: AppTheme.spacingSmall,
          runSpacing: AppTheme.spacingSmall,
          alignment: WrapAlignment.start,
          children: [
            _buildBulkActionButton(context),
            _buildFilterButton(context),
            _buildAddProductButton(context),
          ],
        ),
        if (bulkMode && selectedCount > 0) ...[
          const SizedBox(height: AppTheme.spacingMedium),
          _buildBulkDeleteButton(context),
        ],
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Products',
              style: AppTheme.headingMedium().copyWith(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  forMobile: 20,
                  forTablet: 24,
                  forDesktop: 28,
                ),
              ),
            ),
            Wrap(
              spacing: AppTheme.spacingSmall,
              children: [
                _buildBulkActionButton(context),
                _buildFilterButton(context),
                _buildAddProductButton(context),
              ],
            ),
          ],
        ),
        if (bulkMode && selectedCount > 0) ...[
          const SizedBox(height: AppTheme.spacingMedium),
          _buildBulkDeleteButton(context),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Products',
          style: AppTheme.headingMedium().copyWith(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              forMobile: 20,
              forTablet: 24,
              forDesktop: 28,
            ),
          ),
        ),
        Row(
          children: [
            if (bulkMode && selectedCount > 0) ...[
              _buildBulkDeleteButton(context),
              const SizedBox(width: AppTheme.spacingMedium),
            ],
            _buildBulkActionButton(context),
            const SizedBox(width: AppTheme.spacingMedium),
            _buildFilterButton(context),
            const SizedBox(width: AppTheme.spacingMedium),
            _buildAddProductButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildBulkDeleteButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: bulkDelete,
      icon: const Icon(Icons.delete),
      label: Text('Delete ($selectedCount)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentRed,
        foregroundColor: AppTheme.textPrimary,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveWidth(
            context,
            forMobile: AppTheme.spacingSmall,
            forTablet: AppTheme.spacingMedium,
            forDesktop: AppTheme.spacingMedium,
          ),
          vertical: AppTheme.spacingSmall,
        ),
      ),
    );
  }

  Widget _buildBulkActionButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: toggleBulkMode,
      icon: Icon(bulkMode ? Icons.close : Icons.checklist),
      label: Text(bulkMode ? 'Cancel' : 'Bulk Actions'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveWidth(
            context,
            forMobile: AppTheme.spacingSmall,
            forTablet: AppTheme.spacingMedium,
            forDesktop: AppTheme.spacingMedium,
          ),
          vertical: AppTheme.spacingSmall,
        ),
        backgroundColor: bulkMode ? AppTheme.textMuted : AppTheme.primaryMedium,
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onShowFilters,
      icon: const Icon(Icons.filter_list),
      label: const Text('Filter'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveWidth(
            context,
            forMobile: AppTheme.spacingSmall,
            forTablet: AppTheme.spacingMedium,
            forDesktop: AppTheme.spacingMedium,
          ),
          vertical: AppTheme.spacingSmall,
        ),
        backgroundColor: AppTheme.primaryMedium,
      ),
    );
  }

  Widget _buildAddProductButton(BuildContext context) {
    return ElevatedButton.icon(
     onPressed: () => _navigateToAddProductPage(context),
      icon: const Icon(Icons.add),
      label: const Text('Add Product'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveWidth(
            context,
            forMobile: AppTheme.spacingSmall,
            forTablet: AppTheme.spacingMedium,
            forDesktop: AppTheme.spacingMedium,
          ),
          vertical: AppTheme.spacingSmall,
        ),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _navigateToAddProductPage(BuildContext context) async {
  // Navigate to the new page and wait for a result.
   final result = await Navigator.of(context).push(
     MaterialPageRoute(
       builder: (context) => const ProductCreatePage(),
     ),
  );

   if (result == true && context.mounted) {
     context.read<ProductsListBloc>().add( GetPaginatedProductsEvent(page: 1, pageSize: 20));
   }
 }
}