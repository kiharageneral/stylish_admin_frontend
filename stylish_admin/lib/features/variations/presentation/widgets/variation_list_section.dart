import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variations_entity.dart';

class VariationListSection extends StatelessWidget {
  final List<ProductVariationsEntity> variations;
  final bool showSizesSection;
  final Function(ProductVariationsEntity) onRemoveVariaion;
  final Function(ProductVariationsEntity, String) onRemoveVariationValue;
  const VariationListSection({
    super.key,
    required this.variations,
    required this.showSizesSection,
    required this.onRemoveVariaion,
    required this.onRemoveVariationValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: variations.map((variation) {
        if (variation.name.toLowerCase() == 'size' && showSizesSection) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacingSmall),
          decoration: AppTheme.cardDecoration,
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      variation.name,
                      style: AppTheme.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemoveVariaion(variation),
                      icon: Icon(
                        Icons.delete,
                        size: 20,
                        color: AppTheme.accentRed,
                      ),
                      tooltip: 'Remove variation',
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingSmall),
                Wrap(
                  spacing: AppTheme.spacingSmall,
                  runSpacing: AppTheme.spacingSmall,
                  children: variation.values.map((value) {
                    return Chip(
                      label: Text(
                        value,
                        style: AppTheme.bodySmall().copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                      backgroundColor: AppTheme.primaryLight.withAlpha(
                        (0.2 * 255).round(),
                      ),
                      side: BorderSide(color: AppTheme.borderColor),
                      onDeleted: () => onRemoveVariationValue(variation, value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
