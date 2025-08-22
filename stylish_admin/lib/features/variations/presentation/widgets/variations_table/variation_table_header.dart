
import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variations_table/action_button.dart';

class VariationTableHeader extends StatelessWidget {
  final int totalStock;
  final int currentStock;
  final VoidCallback onGenerateSkus;
  final VoidCallback onShowStockDistribution;
  final VoidCallback onShowBatchPriceUpdate;
  final VoidCallback onShowBatchDiscount;

  const VariationTableHeader({
    super.key,
    required this.totalStock,
    required this.currentStock,
    required this.onGenerateSkus,
    required this.onShowStockDistribution,
    required this.onShowBatchPriceUpdate,
    required this.onShowBatchDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        // Stock indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Total Stock: $totalStock / $currentStock',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Action buttons
        ActionButton(
          onPressed: onGenerateSkus,
          icon: Icons.qr_code,
          label: 'Generate SKUs',
          color: AppTheme.primaryLight,
        ),
        ActionButton(
          onPressed: onShowStockDistribution,
          icon: Icons.inventory,
          label: 'Distribute Stock',
          color: AppTheme.accentBlue,
        ),
        ActionButton(
          onPressed: onShowBatchPriceUpdate,
          icon: Icons.price_change,
          label: 'Batch Update Prices',
          color: AppTheme.accentAmber,
        ),
        ActionButton(
          onPressed: onShowBatchDiscount,
          icon: Icons.discount,
          label: 'Set Discounts',
          color: AppTheme.accentGreen,
        ),
      ],
    );
  }
}