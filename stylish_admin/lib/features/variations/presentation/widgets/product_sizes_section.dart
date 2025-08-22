import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class ProductSizesSection extends StatefulWidget {
  final List<String> initialSizes;
  final TextEditingController? sizesController;
  final Function(List<String>) onSizesChanged;
  final Function(String)? onSizeAdded;
  const ProductSizesSection({
    super.key,
    this.initialSizes = const [],
    this.sizesController,
    required this.onSizesChanged,
    this.onSizeAdded,
  });

  @override
  State<ProductSizesSection> createState() => _ProductSizesSectionState();
}

class _ProductSizesSectionState extends State<ProductSizesSection> {
  late List<String> _sizes;
  late TextEditingController _sizesController;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    _sizes = List.from(widget.initialSizes);

    if (widget.sizesController != null) {
      _sizesController = widget.sizesController!;
    } else {
      _sizesController = TextEditingController();
      _isInternalController = true;
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _sizesController.dispose();
    }
    super.dispose();
  }

  void _addSize(String value) {
    value = value.trim();
    if (value.isNotEmpty && !_sizes.contains(value)) {
      setState(() {
        _sizes.add(value);
        _sizesController.clear();
        widget.onSizesChanged(_sizes);

        if (widget.onSizeAdded != null) {
          widget.onSizeAdded!(value);
        }
      });
    }
  }

  void _removeSize(String size) {
    setState(() {
      _sizes.remove(size);
      widget.onSizesChanged(_sizes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sizes', style: AppTheme.headingMedium()),
        SizedBox(height: AppTheme.spacingMedium),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _sizesController,
                style: AppTheme.bodyMedium(),
                decoration: InputDecoration(
                  hintText: 'Enter size (e.g., S,M,L)',
                  hintStyle: AppTheme.bodyMedium().copyWith(
                    color: AppTheme.textMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                    borderSide: BorderSide(color: AppTheme.primaryLight),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentEmerald,
                ),
                onSubmitted: _addSize,
              ),
            ),
            SizedBox(width: AppTheme.spacingSmall),
            ElevatedButton(
              onPressed: () => _addSize(_sizesController.text),
              child: Text('Add', style: AppTheme.bodyMedium()),
            ),
          ],
        ),

        SizedBox(height: AppTheme.spacingSmall),
        if (_sizes.isNotEmpty)
          Wrap(
            spacing: AppTheme.spacingSmall,
            runSpacing: AppTheme.spacingSmall,
            children: _sizes.map((size) {
              return Chip(
                label: Text(
                  size,
                  style: AppTheme.bodySmall().copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                backgroundColor: AppTheme.primaryLight,
                deleteIconColor: AppTheme.textPrimary,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeSize(size),
                padding: EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSmall,
                  horizontal: AppTheme.spacingSmall,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
