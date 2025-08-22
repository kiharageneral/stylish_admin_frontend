
import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';

class ProductTabsSection extends StatefulWidget {
  final ProductEntity product;

  const ProductTabsSection({
    super.key,
    required this.product,
  });

  @override
  State<ProductTabsSection> createState() => _ProductTabsSectionState();
}

class _ProductTabsSectionState extends State<ProductTabsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabContentHeight = ResponsiveHelper.getResponsiveWidth(
      context,
      forMobile: 250,
      forTablet: 300,
      forDesktop: 350,
      forLargeDesktop: 400,
    );

    final tabLabelStyle = TextStyle(
      fontSize: ResponsiveHelper.getResponsiveFontSize(
        context,
        forMobile: 14,
        forTablet: 15,
        forDesktop: 16,
        forLargeDesktop: 16,
      ),
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: ResponsiveHelper.getSafeHorizontalPadding(context),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(
              top: ResponsiveHelper.getResponsiveWidth(
                context,
                forMobile: AppTheme.spacingMedium,
                forTablet: AppTheme.spacingLarge,
                forDesktop: AppTheme.spacingLarge,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(child: Text('Description', style: tabLabelStyle)),
                Tab(child: Text('Specifications', style: tabLabelStyle)),
                Tab(child: Text('Reviews', style: tabLabelStyle)),
              ],
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryLight,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.isMobile(context) ? 8 : 16,
              ),
            ),
          ),
          
          SizedBox(
            height: tabContentHeight,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Description tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      forMobile: AppTheme.spacingSmall,
                      forTablet: AppTheme.spacingMedium,
                      forDesktop: AppTheme.spacingLarge,
                    ),
                  ),
                  child: Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        forMobile: 14,
                        forTablet: 15,
                        forDesktop: 16,
                        forLargeDesktop: 16,
                      ),
                      height: 1.5,
                    ),
                  ),
                ),

                // Specifications tab 
                Padding(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      forMobile: AppTheme.spacingSmall,
                      forTablet: AppTheme.spacingMedium,
                      forDesktop: AppTheme.spacingLarge,
                    ),
                  ),
                  child: _buildSpecificationsTab(),
                ),

                // Reviews tab
                Padding(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      forMobile: AppTheme.spacingSmall,
                      forTablet: AppTheme.spacingMedium,
                      forDesktop: AppTheme.spacingLarge,
                    ),
                  ),
                  child: _buildReviewsTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    final isSmallScreen = ResponsiveHelper.isMobile(context);
    final titleStyle = TextStyle(
      fontSize: ResponsiveHelper.getResponsiveFontSize(
        context,
        forMobile: 14,
        forTablet: 15,
        forDesktop: 16,
      ),
      fontWeight: FontWeight.bold,
    );
    
    final valueStyle = TextStyle(
      fontSize: ResponsiveHelper.getResponsiveFontSize(
        context,
        forMobile: 14,
        forTablet: 15,
        forDesktop: 16,
      ),
    );

    if (widget.product.variations.isEmpty) {
      return Center(
        child: Text(
          'No specifications available for this product',
          style: valueStyle,
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.product.variations.length,
      itemBuilder: (context, index) {
        final variation = widget.product.variations[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: isSmallScreen ? 8.0 : 12.0,
          ),
          child: isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(variation.name, style: titleStyle),
                    const SizedBox(height: 4),
                    Text(variation.values.join(', '), style: valueStyle),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(variation.name, style: titleStyle),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(variation.values.join(', '), style: valueStyle),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final titleStyle = TextStyle(
      fontSize: ResponsiveHelper.getResponsiveFontSize(
        context,
        forMobile: 18,
        forTablet: 20,
        forDesktop: 22,
      ),
      fontWeight: FontWeight.bold,
    );

    final buttonPadding = EdgeInsets.symmetric(
      horizontal: ResponsiveHelper.getResponsiveWidth(
        context,
        forMobile: 16,
        forTablet: 24,
        forDesktop: 32,
      ),
      vertical: ResponsiveHelper.getResponsiveWidth(
        context,
        forMobile: 8,
        forTablet: 12,
        forDesktop: 16,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Reviews: ${widget.product.rating.count}',
          style: titleStyle,
        ),
        const SizedBox(height: 16),
        if (widget.product.rating.count > 0)
          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to reviews page
                },
                style: ElevatedButton.styleFrom(
                  padding: buttonPadding,
                  textStyle: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      forMobile: 14,
                      forTablet: 15,
                      forDesktop: 16,
                    ),
                  ),
                ),
                child: const Text('View All Reviews'),
              ),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Text(
                'No reviews for this product yet',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    forMobile: 14,
                    forTablet: 15,
                    forDesktop: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}