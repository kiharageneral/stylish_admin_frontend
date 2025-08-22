import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/products/domain/entities/money_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_details/components/stock_info_widget.dart';

class ProductInfoSection extends StatelessWidget {
  final ProductEntity product;

  const ProductInfoSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Get display price using the getter
    final displayPrice = product.displayPrice;

    // Calculate margin (needs to be calculated here since we don't have profitMargin in entity)
    final margin = product.profitMargin ?? 0.0;

    // Get responsive card padding based on screen size
    final cardPadding = ResponsiveHelper.getResponsiveWidth(
      context,
      forMobile: AppTheme.spacingMedium - 4,
      forTablet: AppTheme.spacingMedium,
      forDesktop: AppTheme.spacingMedium + 4,
    );

    // Dynamic spacing based on screen size
    final standardSpacing = ResponsiveHelper.getResponsiveWidth(
      context,
      forMobile: AppTheme.spacingSmall,
      forTablet: AppTheme.spacingMedium,
      forDesktop: AppTheme.spacingMedium,
    );

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero, // Remove default margin to maximize width
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: ResponsiveHelper.buildResponsiveLayout(
          context,
          mobile: _buildMobileLayout(
            context,
            displayPrice,
            margin,
            standardSpacing,
          ),
          tablet: _buildTabletLayout(
            context,
            displayPrice,
            margin,
            standardSpacing,
          ),
          desktop: _buildDesktopLayout(
            context,
            displayPrice,
            margin,
            standardSpacing,
          ),
        ),
      ),
    );
  }

  // Mobile layout - vertical stacking with compact design
  Widget _buildMobileLayout(
    BuildContext context,
    MoneyEntity displayPrice,
    double margin,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductHeader(context),
        SizedBox(height: spacing),

        _buildCategoryInfo(context),
        SizedBox(height: spacing / 2),

        // Price info
        _buildPriceInfo(context, displayPrice),
        SizedBox(height: spacing / 2),

        if (product.cost != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cost: \$${product.cost!.value}',
                style: AppTheme.bodyMedium(),
              ),
              SizedBox(height: spacing / 2),
              Text(
                'Margin: ${margin.toStringAsFixed(2)}%',
                style: AppTheme.bodyMedium(),
              ),
            ],
          ),

        Divider(height: spacing * 1.5),

        // Rating - fixed to prevent overflow
        if (product.rating.value > 0) _buildRatingSection(context),
        SizedBox(height: spacing),

        // Stock info
        StockInfoWidget(product: product),
        Divider(height: spacing * 1.5),

        // Variations
        if (product.variations.isNotEmpty) _buildVariationsSection(context),

        Divider(height: spacing * 1.5),

        // Dates
        _buildDatesSection(context),
      ],
    );
  }

  // Tablet layout - better spacing and some horizontal arrangements
  Widget _buildTabletLayout(
    BuildContext context,
    MoneyEntity displayPrice,
    double margin,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductHeader(context),
        SizedBox(height: spacing),

        _buildCategoryInfo(context),
        SizedBox(height: spacing / 2),

        // Price info
        _buildPriceInfo(context, displayPrice),
        SizedBox(height: spacing / 2),

        if (product.cost != null)
          Wrap(
            spacing: spacing,
            children: [
              Text(
                'Cost: \$${product.cost!.value}',
                style: AppTheme.bodyMedium(),
              ),
              Text(
                'Margin: ${margin.toStringAsFixed(2)}%',
                style: AppTheme.bodyMedium(),
              ),
            ],
          ),

        Divider(height: spacing * 1.5),

        // Rating and stock in separate widgets to prevent overflow
        if (product.rating.value > 0) _buildRatingSection(context),

        if (product.rating.value > 0) SizedBox(height: spacing),

        StockInfoWidget(product: product),

        Divider(height: spacing * 1.5),

        // Variations
        if (product.variations.isNotEmpty) _buildVariationsSection(context),

        Divider(height: spacing * 1.5),

        // Dates
        _buildDatesSection(context),
      ],
    );
  }

  // Desktop layout - optimized for large screens with horizontal layouts
  Widget _buildDesktopLayout(
    BuildContext context,
    MoneyEntity displayPrice,
    double margin,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - basic info
            Expanded(
              flex: 5, // Increased flex to give more room
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductHeader(context),
                  SizedBox(height: spacing),
                  _buildCategoryInfo(context),
                  SizedBox(height: spacing / 2),
                  _buildPriceInfo(context, displayPrice),
                  SizedBox(height: spacing / 2),
                  if (product.cost != null)
                    Wrap(
                      spacing: spacing,
                      children: [
                        Text(
                          'Cost: \$${product.cost!.value}',
                          style: AppTheme.bodyMedium(),
                        ),
                        Text(
                          'Margin: ${margin.toStringAsFixed(2)}%',
                          style: AppTheme.bodyMedium(),
                        ),
                      ],
                    ),
                  SizedBox(height: spacing),
                  if (product.rating.value > 0) _buildRatingSection(context),
                ],
              ),
            ),

            SizedBox(width: spacing * 1.5),

            // Right column - stock and variations
            Expanded(
              flex: 6, // Adjusted to provide better balance
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StockInfoWidget(product: product),
                  SizedBox(height: spacing),
                  if (product.variations.isNotEmpty)
                    _buildVariationsSection(context),
                ],
              ),
            ),
          ],
        ),

        Divider(height: spacing * 1.5),

        // Dates - always at the bottom
        _buildDatesSection(context),
      ],
    );
  }

  Widget _buildProductHeader(BuildContext context) {
    // Use responsive font size for headings
    final headingStyle = AppTheme.headingMedium().copyWith(
      fontSize: ResponsiveHelper.getResponsiveFontSize(
        context,
        forMobile: 18,
        forTablet: 20,
        forDesktop: 22,
      ),
    );

    // Status indicator size based on screen
    final statusPadding = ResponsiveHelper.getResponsiveWidth(
      context,
      forMobile: 6,
      forTablet: 8,
      forDesktop: 10,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(product.name, style: headingStyle)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: statusPadding + 4,
            vertical: statusPadding / 2,
          ),
          decoration: BoxDecoration(
            color: product.isActive ? AppTheme.positive : AppTheme.negative,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            product.isActive ? 'Active' : 'Inactive',
            style: AppTheme.bodySmall().copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveHelper.adaptiveFontSize(
                context,
                12,
                minSize: 10,
                maxSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryInfo(BuildContext context) {
    // Responsive text style
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: ResponsiveHelper.adaptiveFontSize(
        context,
        14,
        minSize: 12,
        maxSize: 16,
      ),
    );

    final boldTextStyle = textStyle?.copyWith(fontWeight: FontWeight.bold);

    return Row(
      children: [
        Text('Category: ', style: textStyle),
        Expanded(
          // Added expanded to prevent overflow
          child: Text(product.category.name, style: boldTextStyle),
        ),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context, MoneyEntity displayPrice) {
    // Responsive price text sizes
    final priceTextSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      forMobile: 20,
      forTablet: 22,
      forDesktop: 24,
      forLargeDesktop: 26,
    );

    final originalPriceTextSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      forMobile: 14,
      forTablet: 16,
      forDesktop: 18,
    );

    return Wrap(
      // Changed to Wrap to prevent overflow
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: ResponsiveHelper.getResponsiveWidth(
        context,
        forMobile: 8,
        forTablet: 10,
        forDesktop: 12,
      ),
      children: [
        Text(
          '\$${displayPrice.value.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontSize: priceTextSize,
          ),
        ),
        if (product.discountPrice != null)
          Text(
            '\$${product.price.value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
              fontSize: originalPriceTextSize,
            ),
          ),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    // Responsive star size
    final starSize = ResponsiveHelper.getResponsiveWidth(
      context,
      forMobile: 18, // Slightly reduced star size
      forTablet: 20,
      forDesktop: 22,
    );

    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: ResponsiveHelper.adaptiveFontSize(
        context,
        14,
        minSize: 12,
        maxSize: 16,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating:',
          style: textStyle?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        // Use Wrap instead of Row to prevent overflow
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2, // Reduced spacing between stars
          runSpacing: 4, // Add spacing between wrapped lines
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < product.rating.value.floor()
                    ? Icons.star
                    : (index < product.rating.value.toDouble()
                          ? Icons.star_half
                          : Icons.star_border),
                size: starSize,
                color: Colors.amber,
              );
            }),
            SizedBox(width: 4), // Reduced spacing
            Text(
              '${product.rating.value.toStringAsFixed(1)} (${product.rating.value.toInt()} reviews)',
              style: textStyle?.copyWith(
                fontSize: ResponsiveHelper.adaptiveFontSize(
                  context,
                  13,
                  minSize: 11,
                  maxSize: 15,
                ), // Slightly reduced
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariationsSection(BuildContext context) {
    // Responsive text sizes and spacing
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: ResponsiveHelper.adaptiveFontSize(
        context,
        16,
        minSize: 14,
        maxSize: 18,
      ),
      fontWeight: FontWeight.bold,
    );

    final subtitleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontSize: ResponsiveHelper.adaptiveFontSize(
        context,
        14,
        minSize: 12,
        maxSize: 16,
      ),
      fontWeight: FontWeight.bold,
    );

    final chipSpacing = ResponsiveHelper.getResponsiveWidth(
      context,
      forMobile: 6,
      forTablet: 8,
      forDesktop: 10,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Variations:', style: titleStyle),
        SizedBox(height: 8),
        ...product.variations.map((variation) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(variation.name, style: subtitleStyle),
              SizedBox(height: 4),
              Wrap(
                spacing: chipSpacing,
                runSpacing: chipSpacing,
                children: variation.values.map((value) {
                  return Chip(
                    label: Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.adaptiveFontSize(
                          context,
                          12,
                          minSize: 10,
                          maxSize: 14,
                        ),
                      ),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withAlpha((0.1 * 255).round()),
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.isMobile(context) ? 4 : 8,
                      vertical: 0,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  // product_info_section.dart

  Widget _buildDatesSection(BuildContext context) {
    // Use smaller font on mobile
    final dateStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: ResponsiveHelper.adaptiveFontSize(
        context,
        12,
        minSize: 10,
        maxSize: 14,
      ),
    );

    final List<Widget> dateWidgets = [];

    // Safely add the 'Created' date text if it exists
    if (product.createdAt != null) {
      dateWidgets.add(
        Text(
          'Created: ${DateFormat('MMM d, yyyy').format(product.createdAt!)}',
          style: dateStyle,
        ),
      );
    }

    // Safely add the 'Updated' date text if it exists
    if (product.updatedAt != null) {
      dateWidgets.add(
        Text(
          'Updated: ${DateFormat('MMM d, yyyy').format(product.updatedAt!)}',
          style: dateStyle,
        ),
      );
    }

    // If there are no dates, return an empty, non-rendering widget
    if (dateWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use a Wrap to display the dates
    return Wrap(spacing: 16, runSpacing: 4, children: dateWidgets);
  }
}
