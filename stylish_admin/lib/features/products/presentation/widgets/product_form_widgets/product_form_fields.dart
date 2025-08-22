import 'package:flutter/material.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_form_widgets/product_category_dropdown.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';

class ProductFormFields extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController discountPriceController;
  final TextEditingController stockController;
  final TextEditingController costController;
  final TextEditingController initialStockController;
  final TextEditingController sizesController;
  final TextEditingController profitMarginController;

  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final List<String> sizes;
  final Map<String, List<String>> variations;
  final List<ProductVariantEntity>? variants;
  final String? productId;
  final bool isActive;
  final bool isUpdateMode;

  final Function() onCalculateProfitMargin;
  final Function(String) onSizeAdded;
  final Function(String?, String?) onCategoryChanged;
  final Function(Map<String, List<String>>) onVariationsChanged;
  final Function(List<ProductVariantEntity>) onVariantsChanged;
  final Function(List<String>) onSizesChanged;
  final Function(bool) onActiveChanged;

  const ProductFormFields({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.discountPriceController,
    required this.stockController,
    required this.costController,
    required this.initialStockController,
    required this.sizesController,
    required this.profitMarginController,
    required this.selectedCategoryId,
    required this.selectedCategoryName,
    required this.sizes,
    required this.variations,
    this.variants,
    this.productId,
    required this.isActive,
    required this.onCalculateProfitMargin,
    required this.onSizeAdded,
    required this.onCategoryChanged,
    required this.onVariationsChanged,
    required this.onVariantsChanged,
    required this.onSizesChanged,
    required this.onActiveChanged,
    this.isUpdateMode = false,
  });

  @override
  State<ProductFormFields> createState() => _ProductFormFieldsState();
}

class _ProductFormFieldsState extends State<ProductFormFields> {
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    return isSmallScreen ? _buildMobileLayout() : _buildDesktopLayout();
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(flex: 1, child: _buildLeftColumn()),
        const SizedBox(width: 24),
        Flexible(flex: 1, child: _buildRightColumn()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLeftColumn(),
        const SizedBox(height: 24),
        _buildRightColumn(),
      ],
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: widget.nameController,
          label: 'Product Name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter product name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: widget.descriptionController,
          label: 'Description',
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter product description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          children: [
            Flexible(
              child: _buildTextField(
                controller: widget.costController,
                label: 'Cost',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid cost';
                  }
                  return null;
                },
                onChanged: (value) {
                  widget.onCalculateProfitMargin();
                },
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: _buildTextField(
                controller: widget.priceController,
                label: 'Price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid price';
                  }
                  return null;
                },
                onChanged: (value) {
                  widget.onCalculateProfitMargin();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          children: [
            Flexible(
              child: _buildTextField(
                controller: widget.discountPriceController,
                label: 'Discount Price (Optional)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid price';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: _buildTextField(
                controller: widget.profitMarginController,
                label: 'Profit Margin %',
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isUpdateMode)
          _buildTextField(
            controller: widget.initialStockController,
            label: 'Initial Stock',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter initial stock';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter valid initial stock';
              }
              return null;
            },
          ),
        if (!widget.isUpdateMode) const SizedBox(height: 16),
        ProductCategoryDropdown(
          selectedCategoryId: widget.selectedCategoryId,
          onCategoryChanged: widget.onCategoryChanged,
        ),
        const SizedBox(height: 16),

        if (widget.productId == null || widget.productId!.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Save product first before managing variations',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Active Status'),
          value: widget.isActive,
          onChanged: widget.onActiveChanged,
          contentPadding: EdgeInsets.zero,
        ),
        if (widget.variants != null && widget.variants!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Total Stock: ${widget.variants!.fold(0, (sum, variant) => sum + variant.stock)} (${widget.variants!.length} variants)",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Manage in inventory →",
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResponsiveRow({required List<Widget> children}) {
    final isSmallScreen = MediaQuery.of(context).size.width < 576;

    return isSmallScreen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children:
                children
                    .expand((child) => [child, const SizedBox(height: 16)])
                    .toList()
                  ..removeLast(),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
    );
  }
}
