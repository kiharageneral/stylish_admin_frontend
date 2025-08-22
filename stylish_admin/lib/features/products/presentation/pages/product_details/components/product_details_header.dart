import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';

class ProductDetailsHeader extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  const ProductDetailsHeader({
    super.key,
    required this.product,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: ResponsiveHelper.buildResponsiveLayout(
        context,
        mobile: _buildMobileLayout(context),
        tablet: _builTabletLayout(context),
        desktop: _builDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              iconSize: ResponsiveHelper.adaptiveFontSize(context, 24),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Text(
              'Product Details',
              style: AppTheme.headingMedium().copyWith(
                fontSize: ResponsiveHelper.adaptiveFontSize(context, 18),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingMedium),
        Wrap(
          spacing: AppTheme.spacingSmall,
          runSpacing: AppTheme.spacingSmall,
          children: [
            SizedBox(
              width: ResponsiveHelper.getWidthPercentage(context, 100),
              child: ElevatedButton.icon(
                onPressed: onEditPressed,
                label: const Text('Edit Product'),
                icon: const Icon(Icons.edit),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSmall,
                  ),
                ),
              ),
            ),

            SizedBox(
              width: ResponsiveHelper.getWidthPercentage(context, 100),
              child: ElevatedButton.icon(
                onPressed: onDeletePressed,
                label: const Text('Delete'),
                icon: const Icon(Icons.delete),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.negative,
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _builTabletLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              iconSize: ResponsiveHelper.adaptiveFontSize(context, 24),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Text(
              'Product Details',
              style: AppTheme.headingMedium().copyWith(
                fontSize: ResponsiveHelper.adaptiveFontSize(context, 18),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEditPressed,
                label: const Text('Edit Product'),
                icon: const Icon(Icons.edit),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSmall,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDeletePressed,
                label: const Text('Delete'),
                icon: const Icon(Icons.delete),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.negative,
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _builDesktopLayout(BuildContext context) {
    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      forMobile: 16,
      forTablet: 16,
      forDesktop: 18,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              iconSize: ResponsiveHelper.adaptiveFontSize(context, 24),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Text(
              'Product Details',
              style: AppTheme.headingMedium().copyWith(fontSize: fontSize),
            ),
          ],
        ),

        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onEditPressed,
              label: const Text('Edit Product'),
              icon: const Icon(Icons.edit),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSmall,
                  horizontal: AppTheme.spacingMedium,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton.icon(
              onPressed: onDeletePressed,
              label: const Text('Delete'),
              icon: const Icon(Icons.delete),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.negative,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSmall,
                  horizontal: AppTheme.spacingMedium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
