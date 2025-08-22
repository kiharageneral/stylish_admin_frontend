import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class StockWarningBanner extends StatelessWidget {
  final int stockDifference;
  final VoidCallback onDistributeStock;
  const StockWarningBanner({
    super.key,
    required this.stockDifference,
    required this.onDistributeStock,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = stockDifference > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        color: isPositive
            ? (isDark
                  ? AppTheme.accentAmber.withAlpha((0.2 * 255).round())
                  : Colors.amber.shade50)
            : (isDark
                  ? AppTheme.negative.withAlpha((0.2 * 255).round())
                  : Colors.red.shade50),
        border: Border.all(
          color: isPositive
              ? (isDark ? AppTheme.accentAmber : Colors.amber.shade300)
              : (isDark ? AppTheme.negative : Colors.red.shade300),
        ),
      ),

      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? Icons.warning_amber_rounded : Icons.error_outline,
            color: isPositive
                ? (isDark ? AppTheme.accentAmber : Colors.amber.shade700)
                : (isDark ? AppTheme.negative : Colors.red.shade700),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive
                      ? 'Unallocated Stock'
                      : 'Stock Allocation Exceeds Product stock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPositive
                      ? 'You have ${stockDifference.abs()} unit${stockDifference != 1}? "s":"" of product stock not allocated to any variant'
                      : 'Your variants have more units that your product stock.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onDistributeStock,
                      label: Text(
                        isPositive
                            ? 'Distribute Remaining Stock '
                            : 'Update product stock',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
