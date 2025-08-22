import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variations_entity.dart';
import 'package:stylish_admin/features/variations/presentation/bloc/product_variant_bloc.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/add_variation_dialog.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/product_sizes_section.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/update_stock_dialog.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variation_list_section.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variations_table/variation_combinations_table.dart';

class ProductVariationsManager extends StatefulWidget {
  final String productId;
  final Map<String, List<String>> initialVariations;
  final List<ProductVariantEntity>? initialVariants;
  final List<String> initialSizes;
  final double basePrice;
  final int currentStock;
  final Function(Map<String, List<String>>, List<ProductVariantEntity>)?
  onVariationsChanges;

  const ProductVariationsManager({
    super.key,
    required this.productId,
    this.initialVariations = const {},
    this.initialVariants,
    this.initialSizes = const [],
    required this.basePrice,
    this.currentStock = 0,
    this.onVariationsChanges,
  });

  @override
  State<ProductVariationsManager> createState() =>
      _ProductVariationsManagerState();
}

class _ProductVariationsManagerState extends State<ProductVariationsManager> {
  bool _showCombinations = true;
  final bool _showSizesSection = true;

  @override
  void initState() {
    super.initState();
    // Initialize the BLoC with all necessary data
    context.read<ProductVariantBloc>().add(
      InitializeVariationsDataEvent(
        productId: widget.productId,
        initialVariations: widget.initialVariations,
        initialSizes: widget.initialSizes,
        basePrice: widget.basePrice,
        currentStock: widget.currentStock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductVariantBloc, ProductVariantState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.negative,
            ),
          );
        }
        if (state.isOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Operation successful'),
              backgroundColor: AppTheme.positive,
            ),
          );
        }
      },
      builder: (context, state) {
        final variations = state.variations;
        final variants = state.variants ?? [];
        final totalStockFromVariants = variants.fold(
          0,
          (sum, v) => sum + v.stock,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: AppTheme.accentIvory),
                    const SizedBox(width: 8),
                    Text(
                      'Product Stock (Overall): ${widget.currentStock}',
                      style: AppTheme.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showSizesSection) ...[
              ProductSizesSection(
                initialSizes: variations
                    .firstWhere(
                      (v) => v.name.toLowerCase() == 'size',
                      orElse: () => const ProductVariationsEntity(
                        id: '',
                        name: '',
                        values: [],
                      ),
                    )
                    .values,
                onSizesChanged: (sizes) {
                  context.read<ProductVariantBloc>().add(
                    UpdateSizesDefinitionEvent(sizes),
                  );
                },
              ),
              SizedBox(height: AppTheme.spacingLarge),
              Divider(color: AppTheme.dividerColor),
              SizedBox(height: AppTheme.spacingMedium),
            ],

            _buildVariationsHeader(
              context,
              state.isDirty,
              variations.isNotEmpty,
            ),

            SizedBox(height: AppTheme.spacingSmall),

            VariationListSection(
              variations: variations,
              showSizesSection: _showSizesSection,
              onRemoveVariaion: (variation) {
                context.read<ProductVariantBloc>().add(
                  RemoveVariationDefinitionEvent(variation),
                );
              },
              onRemoveVariationValue: (variation, value) {
                context.read<ProductVariantBloc>().add(
                  RemoveVariationValueEvent(variation: variation, value: value),
                );
              },
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddVariationDialog(context),
                  label: const Text('Add Variation Type'),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.accentIvory,
                  ),
                  style: _buttonStyle(),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: variants.isNotEmpty
                      ? () => _showUpdateStockDialog(
                          context,
                          totalStockFromVariants,
                        )
                      : null,
                  label: const Text('Distribute Stock'),
                  icon: const Icon(Icons.sync_alt, color: AppTheme.textPrimary),
                  style: _buttonStyle(primary: true),
                ),
              ],
            ),
            _buildStatusIndicator(state),

            if (_showCombinations && variations.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacingLarge),
              Divider(color: AppTheme.dividerColor),
              SizedBox(height: AppTheme.spacingMedium),
              Text('Variation Combinations', style: AppTheme.headingMedium()),
              SizedBox(height: AppTheme.spacingMedium),

              VariationCombinationsTable(
                variations: variations,
                variants: variants,
                basePrice: widget.basePrice,
                onVariantsChanged: (updatedVariants) {
                  context.read<ProductVariantBloc>().add(
                    LocalVariantsUpdatedEvent(updatedVariants),
                  );
                },
                productId: widget.productId,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatusIndicator(ProductVariantState state) {
    if (state.isOperationLoading || state.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentIvory),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  ButtonStyle _buttonStyle({bool primary = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary
          ? AppTheme.accentBlue
          : AppTheme.accentBlue.withAlpha((0.1 * 255).round()),
      foregroundColor: primary ? AppTheme.textPrimary : AppTheme.accentSilver,
      elevation: 0,
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLarge,
        vertical: AppTheme.spacingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: primary
            ? BorderSide.none
            : BorderSide(color: AppTheme.primaryLight, width: 1.5),
      ),
    );
  }

  void _showAddVariationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddVariationDialog(
        onAddVariation: (name, values) {
          context.read<ProductVariantBloc>().add(
            AddVariationDefinitionEvent(name: name, values: values),
          );
        },
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, int currentTotalStock) {
    showDialog(
      context: context,
      builder: (_) => UpdateStockDialog(
        currentStock: currentTotalStock,
        onUpdateStock: (newStock) {
          context.read<ProductVariantBloc>().add(
            DistributeStockAcrossVariantsEvent(newStock),
          );
        },
      ),
    );
  }

  Widget _buildVariationsHeader(
    BuildContext context,
    bool isDirty,
    bool hasVariations,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Product Variations',
            style: AppTheme.headingMedium(),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        Row(
          children: [
            if (hasVariations)
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showCombinations = !_showCombinations),
                label: Text(_showCombinations ? 'Hide' : 'Show'),
                icon: Icon(
                  _showCombinations ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),

            if (isDirty)
              TextButton.icon(
                onPressed: () => context.read<ProductVariantBloc>().add(
                  SaveVariationsEvent(),
                ),
                label: Text(
                  'Save Variations',
                  style: AppTheme.bodyMedium().copyWith(
                    color: AppTheme.accentGreen,
                  ),
                ),
                icon: Icon(Icons.save, color: AppTheme.accentBlue, size: 20),
              ),
          ],
        ),
      ],
    );
  }
}
