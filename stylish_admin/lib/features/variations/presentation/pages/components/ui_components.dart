import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/variations/presentation/bloc/product_variant_bloc.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/product_variations_manager.dart';

class VariationsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool hasChanges;
  final VoidCallback onSave;
  final VoidCallback onShowHelp;
  final VoidCallback onBack;
  const VariationsAppBar({
    super.key,
    required this.hasChanges,
    required this.onSave,
    required this.onShowHelp,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Product Variations',
        style: AppTheme.headingMedium().copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
      ),
      backgroundColor: AppTheme.primaryMedium,
      elevation: 0,
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.borderRadiusMedium),
          bottomRight: Radius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
      actions: [
        if (hasChanges)
          BlocBuilder<ProductVariantBloc, ProductVariantState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingMedium),
                child: IconButton(
                  onPressed: state.isOperationLoading ? null : onSave,
                  tooltip: 'Save Changes',
                  icon: state.isOperationLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textPrimary,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                          color: AppTheme.textPrimary,
                        ),
                ),
              );
            },
          ),
        IconButton(
          onPressed: onShowHelp,
          icon: const Icon(Icons.help_outline, color: AppTheme.textPrimary),
          tooltip: 'Help',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Header sectio with gradient background
class VariationsHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const VariationsHeader({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withAlpha((0.9 * 255).round()),
            AppTheme.primaryLight.withAlpha((0.7 * 255).round()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withAlpha((0.3 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure product variations',
                    style: AppTheme.headingMedium().copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    'Create and manage options like size, color, and material',
                    style: AppTheme.bodyMedium().copyWith(
                      color: Colors.white.withAlpha((0.9 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh variants',
            ),
          ],
        ),
      ),
    );
  }
}

// Main card containing variation functionality
class VariationsCard extends StatelessWidget {
  final String productId;
  final double basePrice;
  final int currentStock;

  const VariationsCard({
    super.key,
    required this.productId,
    required this.basePrice,
    required this.currentStock,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductVariantBloc, ProductVariantState>(
      builder: (context, state) {
        final variants = state.variants ?? [];
        return Card(
          elevation: 4,
          color: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context),
                Divider(height: 32, color: AppTheme.dividerColor),
                StatusOverView(
                  totalVariants: variants.length,
                  inStockVariants: variants.where((v) => v.stock > 0).length,
                  basePrice: basePrice,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                ProductVariationsManager(
                  productId: productId,
                  basePrice: basePrice,
                  currentStock: currentStock,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Icon(Icons.category, color: AppTheme.textPrimary),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Text(
              'Product Variations',
              style: AppTheme.headingMedium().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          'Create and manage different variations of your product such as size, color, material, etc. Each variation combination will create a unique product variant with its own price, stock and SKU.',
          style: AppTheme.bodyMedium().copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class StatusOverView extends StatelessWidget {
  final int totalVariants;
  final int inStockVariants;
  final double basePrice;
  const StatusOverView({
    super.key,
    required this.totalVariants,
    required this.inStockVariants,
    required this.basePrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMedium,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          final statusCards = [
            _buildStatusCard(
              title: 'Total Variants',
              value: totalVariants.toString(),
              icon: Icons.grid_view,
              iconColor: AppTheme.primaryLight,
              isSmallScreen: isSmallScreen,
            ),
            _buildStatusCard(
              title: 'In Stock',
              value: inStockVariants.toString(),
              icon: Icons.inventory,
              iconColor: AppTheme.positive,
              isSmallScreen: isSmallScreen,
            ),
            _buildStatusCard(
              title: 'Out of Stock',
              value: (totalVariants - inStockVariants).toString(),
              icon: Icons.inventory_2_outlined,
              iconColor: AppTheme.negative,
              isSmallScreen: isSmallScreen,
            ),
            _buildStatusCard(
              title: 'Base Price',
              value: '\$${basePrice.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              iconColor: AppTheme.warning,
              isSmallScreen: isSmallScreen,
            ),
          ];

          if (isSmallScreen) {
            return Wrap(
              spacing: AppTheme.spacingMedium,
              runSpacing: AppTheme.spacingMedium,
              alignment: WrapAlignment.spaceAround,
              children: statusCards,
            );
          } else {
            return Row(
              children: statusCards
                  .map((card) => Expanded(child: card))
                  .toList(),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        width: isSmallScreen ? 150 : null,
        padding: const EdgeInsets.all(AppTheme.spacingSmall),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 20),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  title,
                  style: AppTheme.bodyMedium().copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              value,
              style: AppTheme.headingLarge().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomActionsBar extends StatelessWidget {
  final bool hasChanges;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isLoading;
  const BottomActionsBar({
    super.key,
    required this.hasChanges,
    required this.onSave,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: onCancel,
            label: Text('Cancel', style: AppTheme.bodyMedium()),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacingMedium),
          ElevatedButton.icon(
            onPressed: hasChanges && !isLoading ? onSave : null,
            label: Text(
              'Save Variations',
              style: AppTheme.bodyMedium().copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textPrimary,
                    ),
                  )
                : const Icon(Icons.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: AppTheme.textPrimary,
              disabledBackgroundColor: AppTheme.accentSilver,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLarge,
                vertical: AppTheme.spacingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
