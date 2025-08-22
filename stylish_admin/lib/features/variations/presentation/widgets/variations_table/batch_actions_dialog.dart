
import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class BatchActionDialogs {
  /// Creates a dialog for distributing stock across variants
  static Widget stockDistributionDialog(
    BuildContext context, {
    required Function(int) onDistribute,
  }) {
    int stockToDistribute = 0;

    return Builder(builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Distribute Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Enter the total stock to distribute evenly across all variants:'),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Stock',
                helperText:
                    'Stock will be distributed evenly with remainder going to first variants',
              ),
              onChanged: (value) {
                stockToDistribute = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Note: This will update the stock of all variants. This is a stock distribution operation.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            // Use the new dialogContext to pop only the dialog
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (stockToDistribute > 0) {
                onDistribute(stockToDistribute);
                // Use the new dialogContext to pop only the dialog
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Distribute'),
          ),
        ],
      );
    });
  }

  /// Creates a dialog for batch updating prices across variants
  static Widget batchPriceUpdateDialog(
    BuildContext context, {
    required Function(double, bool) onUpdatePrices,
  }) {
    final TextEditingController controller = TextEditingController();
    bool isPercentage = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StatefulBuilder(
      // The context from StatefulBuilder is correct for this dialog's scope.
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: isDark ? AppTheme.backgroundDark : Colors.white,
        title: Text(
          'Batch Update Prices',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a modifier to apply to all variant prices:',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Price Modifier',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                prefixIcon: Icon(
                  isPercentage ? Icons.percent : Icons.attach_money,
                  color: isDark ? Colors.white70 : null,
                ),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                ),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(
                      'Percentage',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    value: true,
                    groupValue: isPercentage,
                    onChanged: (value) {
                      setDialogState(() {
                        isPercentage = value!;
                      });
                    },
                    activeColor: AppTheme.primaryLight,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(
                      'Fixed Amount',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    value: false,
                    groupValue: isPercentage,
                    onChanged: (value) {
                      setDialogState(() {
                        isPercentage = value!;
                      });
                    },
                    activeColor: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.primaryLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final modifier = double.tryParse(controller.text);
              if (modifier != null) {
                onUpdatePrices(modifier, isPercentage);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Creates a dialog for batch setting discounts across variants
  static Widget batchDiscountDialog(
    BuildContext context, {
    required Function(double) onUpdateDiscounts,
  }) {
    final TextEditingController controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // FIX: Wrap with a Builder to get the correct dialog context.
    return Builder(
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.backgroundDark : Colors.white,
          title: Text(
            'Batch Set Discounts',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter discount percentage to apply to all variants:',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Discount %',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                  suffixIcon: const Icon(Icons.percent),
                  labelStyle: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              // FIX: Use the dialog's context to pop.
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.primaryLight,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final discount = double.tryParse(controller.text);
                if (discount != null) {
                  onUpdateDiscounts(discount);
                  // FIX: Use the dialog's context to pop.
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      }
    );
  }
}