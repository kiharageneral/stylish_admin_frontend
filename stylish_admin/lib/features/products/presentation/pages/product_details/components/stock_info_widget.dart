import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';

class StockInfoWidget extends StatelessWidget {
  final ProductEntity product;

  const StockInfoWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final stockPercentage =
        product.initialStock != null && product.initialStock! > 0
        ? (product.stock / product.initialStock!) * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Stock:', style: AppTheme.bodyLarge()),
            Text(
              '${product.stock} / ${product.initialStock ?? product.stock}',
              style: AppTheme.bodyLarge().copyWith(
                fontWeight: FontWeight.bold,
                color: _getStockColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        LinearProgressIndicator(
          value: stockPercentage / 100,
          backgroundColor: AppTheme.dividerColor,
          color: _getStockColor(),
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall / 2),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          _getStockStatusText(),
          style: AppTheme.bodySmall().copyWith(
            color: _getStockColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStockColor() {
    switch (product.stockStatus) {
      case StockStatus.outOfStock:
        return AppTheme.negative;
      case StockStatus.lowStock:
        return AppTheme.accentOrange;

      case StockStatus.inStock:
        return AppTheme.positive;
    }
  }

  String _getStockStatusText() {
    return product.stockStatus.displayName;
  }
}
