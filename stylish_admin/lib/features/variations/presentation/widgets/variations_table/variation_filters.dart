import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class VariationFilters extends StatelessWidget {
  final List<String> availableSizes;
  final List<String> availableColors;
  final String? selectedSize;
  final String? selectedColor;
  final Function(String?) onSizeChanged;
  final Function(String?) onColorChanged;
  const VariationFilters({
    super.key,
    required this.availableSizes,
    required this.availableColors,
    this.selectedSize,
    this.selectedColor,
    required this.onSizeChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Size filter
        if (availableSizes.isNotEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Filter by Size',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                value: selectedSize,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Sizes'),
                  ),
                  ...availableSizes.map(
                    (size) => DropdownMenuItem<String?>(
                      value: size,
                      child: Text(size),
                    ),
                  ),
                ],
                onChanged: onSizeChanged,
              ),
            ),
          ),

        // Color filter
        if (availableColors.isNotEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Filter by Color',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                value: selectedColor,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Colors'),
                  ),
                  ...availableColors.map(
                    (color) => DropdownMenuItem<String?>(
                      value: color,
                      child: Text(color),
                    ),
                  ),
                ],
                onChanged: onColorChanged,
              ),
            ),
          ),
      ],
    );
  }
}
