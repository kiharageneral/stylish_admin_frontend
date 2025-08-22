import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';

class VariationPriceCell extends StatelessWidget {
  final ProductVariantEntity variant;
  final double basePrice;
  final bool isEditing;
  final Function(double?) onChanged;
  const VariationPriceCell({
    super.key,
    required this.variant,
    required this.basePrice,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return isEditing
        ? TextFormField(
            initialValue: variant.price.value.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              prefixText: variant.price.currency == 'USD'
                  ? '\$'
                  : variant.price.currency,
              prefixStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
            onChanged: (value) {
              final price = double.tryParse(value);
              onChanged(price);
            },
          )
        : Text(
            '${variant.price.currency == 'USD' ? '\$' : variant.price.currency} ${variant.price.value.toStringAsFixed(2)}',
            style: TextStyle(
              color: variant.price.value > basePrice
                  ? isDark
                        ? AppTheme.positive
                        : AppTheme.positive
                  : variant.price.value < basePrice
                  ? isDark
                        ? AppTheme.negative
                        : AppTheme.negative
                  : textColor,
              fontWeight: FontWeight.w500,
            ),
          );
  }
}

class VariationStockCell extends StatelessWidget {
  final ProductVariantEntity variant;
  final bool isEditing;
  final Function(int?) onChanged;
  const VariationStockCell({
    super.key,
    required this.variant,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return isEditing
        ? TextFormField(
            initialValue: variant.stock.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: TextStyle(color: textColor),
            onChanged: (value) {
              final stock = int.tryParse(value);
              onChanged(stock);
            },
          )
        : Text(
            variant.stock.toString(),
            style: TextStyle(
              color: variant.stock <= 5
                  ? isDark
                        ? AppTheme.negative
                        : AppTheme.negative
                  : textColor,
              fontWeight: FontWeight.w500,
            ),
          );
  }
}

class VariationSkuCell extends StatelessWidget {
  final ProductVariantEntity variant;
  final bool isEditing;
  final Function(String?) onChanged;
  const VariationSkuCell({
    super.key,
    required this.variant,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return isEditing
        ? TextFormField(
            initialValue: variant.sku ?? '',
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: TextStyle(color: textColor),
            onChanged: (value) {
              onChanged(value.isNotEmpty ? value : null);
            },
          )
        : Text(
            variant.sku ?? '-',
            style: TextStyle(
              color: variant.sku == null
                  ? isDark
                        ? AppTheme.textMuted
                        : AppTheme.textMuted
                  : textColor,
              fontWeight: FontWeight.w500,
              fontStyle: variant.sku == null
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          );
  }
}

class VariationDiscountCell extends StatelessWidget {
  final ProductVariantEntity variant;
  final bool isEditing;
  final Function(double?) onChanged;
  const VariationDiscountCell({
    super.key,
    required this.variant,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return isEditing
        ? TextFormField(
            initialValue: variant.discountPrice?.value.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              prefixText: variant.price.currency == 'USD'
                  ? '\$'
                  : variant.price.currency,
              prefixStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
            onChanged: (value) {
              if (value.isEmpty) {
                onChanged(null);
              } else {
                final discount = double.tryParse(value);
                onChanged(discount);
              }
            },
          )
        : Text(
            variant.discountPrice != null
                ? '${variant.price.currency == 'USD' ? '\$' : variant.price.currency}${variant.discountPrice!.value.toStringAsFixed(2)}'
                : '-',
            style: TextStyle(
              color: variant.isOnSale
                  ? isDark
                        ? AppTheme.positive
                        : AppTheme.positive
                  : AppTheme.textMuted,
              fontWeight: variant.isOnSale
                  ? FontWeight.w500
                  : FontWeight.normal,
                  fontStyle: variant.isOnSale 
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          );
  }
}
