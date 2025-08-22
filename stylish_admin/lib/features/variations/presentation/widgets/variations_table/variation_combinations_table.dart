import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/products/domain/entities/money_entity.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variations_entity.dart';
import 'package:stylish_admin/features/variations/presentation/bloc/product_variant_bloc.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variations_table/batch_actions_dialog.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variations_table/filter_stats_header.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variations_table/stock_warning_banner.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variations_table/variation_filters.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variations_table/variation_table_body.dart';
import 'package:stylish_admin/features/variations/presentation/widgets/variations_table/variation_table_header.dart';

class VariationCombinationsTable extends StatefulWidget {
  final List<ProductVariationsEntity> variations;
  final List<ProductVariantEntity> variants;
  final double basePrice;
  final Function(List<ProductVariantEntity>) onVariantsChanged;
  final String productId;
  final int currentStock;
  const VariationCombinationsTable({
    super.key,
    required this.variations,
    required this.variants,
    required this.basePrice,
    required this.onVariantsChanged,
    required this.productId,
    this.currentStock = 0,
  });

  @override
  State<VariationCombinationsTable> createState() =>
      _VariationCombinationsTableState();
}

class _VariationCombinationsTableState
    extends State<VariationCombinationsTable> {
  late List<ProductVariantEntity> _localVariants;
  bool _editingPrice = false;
  bool _editingStock = false;
  bool _editingSku = false;
  bool _editingDiscount = false;

  String? _selectedSize;
  String? _selectedColor;
  List<String> _availableSizes = [];
  List<String> _availableColors = [];

  @override
  void initState() {
    super.initState();
    _updateLocalStateFromWidget();
  }

  int get _totalLocalStock => _localVariants.fold(0, (sum, v) => sum + v.stock);

  void _updateLocalStateFromWidget() {
    _localVariants = List.from(widget.variants);
    _extractVariationOptions();
  }

  void _extractVariationOptions() {
    _availableSizes = widget.variations
        .firstWhere(
          (v) => v.name.toLowerCase() == 'size',
          orElse: () =>
              const ProductVariationsEntity(id: '', name: '', values: []),
        )
        .values;

    _availableColors = widget.variations
        .firstWhere(
          (v) => v.name.toLowerCase() == 'color',
          orElse: () =>
              const ProductVariationsEntity(id: '', name: '', values: []),
        )
        .values;
  }

  List<ProductVariantEntity> _getFilteredVariants() {
    return _localVariants.where((variant) {
      bool matchesSize =
          _selectedSize == null || variant.attributes['Size'] == _selectedSize;
      bool matchesColor =
          _selectedColor == null ||
          variant.attributes['Color'] == _selectedColor;
      return matchesSize && matchesColor;
    }).toList();
  }

  void _generateSkus() {
    setState(() {
      _localVariants = _localVariants.map((variant) {
        final attrebutesStr = variant.attributes.entries
            .map((e) => e.value.substring(0, min(2, e.value.length)))
            .join('');
        final sku =
            'SKU-${attrebutesStr.toUpperCase()}-${variant.id.substring(0, 4)}';
        return variant.copyWith(sku: sku);
      }).toList();
      widget.onVariantsChanged(_localVariants);
    });
  }

  void _distributeStock(int totalStock) {
    if (_localVariants.isEmpty || totalStock < 0) return;

    final int stockPerVariant = totalStock ~/ _localVariants.length;
    final int remainder = totalStock % _localVariants.length;

    setState(() {
      for (int i = 0; i < _localVariants.length; i++) {
        final stock = i < remainder ? stockPerVariant + 1 : stockPerVariant;
        _localVariants[i] = _localVariants[i].copyWith(stock: stock);
      }
      widget.onVariantsChanged(_localVariants);
    });
  }

  void _batchUpdatePrices(double priceModifier, bool isPercentage) {
    setState(() {
      _localVariants = _localVariants.map((variant) {
        double newValue = isPercentage
            ? variant.price.value * (1 + priceModifier / 100)
            : variant.price.value + priceModifier;
        return variant.copyWith(price: MoneyEntity(value: max(0, newValue)));
      }).toList();
      widget.onVariantsChanged(_localVariants);
    });
  }

  void _batchUpdateDiscounts(double discountPercentage) {
    setState(() {
      _localVariants = _localVariants.map((variant) {
        if (discountPercentage <= 0) {
          return variant.copyWith(discountPrice: null);
        }
        final discountValue =
            variant.price.value * (1 - discountPercentage / 100);
        return variant.copyWith(
          discountPrice: MoneyEntity(value: max(0, discountValue)),
        );
      }).toList();
      widget.onVariantsChanged(_localVariants);
    });
  }

  void _updateVariant(int index, ProductVariantEntity updated) {
    final masterIndex = _localVariants.indexWhere((v) => v.id == updated.id);
    if (masterIndex != -1) {
      setState(() {
        _localVariants[masterIndex] = updated;
        widget.onVariantsChanged(_localVariants);
      });
    }
  }

  @override
  void didUpdateWidget(covariant VariationCombinationsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variants != oldWidget.variants) {
      _updateLocalStateFromWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayVariants = _getFilteredVariants();
    final stockDifference = widget.currentStock - _totalLocalStock;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardBackground : AppTheme.textPrimary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock discepancy warning
            if (stockDifference != 0)
              StockWarningBanner(
                stockDifference: stockDifference,
                onDistributeStock: () => context.read<ProductVariantBloc>().add(
                  DistributeStockAcrossVariantsEvent(widget.currentStock),
                ),
              ),

            // Filters
            VariationFilters(
              availableSizes: _availableSizes,
              availableColors: _availableColors,
              selectedColor: _selectedColor,
              selectedSize: _selectedSize,
              onSizeChanged: (size) {
                setState(() {
                  _selectedSize = size;
                });
              },
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            const SizedBox(height: 16),
            // Table header with action buttons
            VariationTableHeader(
              totalStock: _totalLocalStock,
              currentStock: widget.currentStock,
              onGenerateSkus: _generateSkus,
              onShowStockDistribution: () => _showDialog(
                context,
                BatchActionDialogs.stockDistributionDialog(
                  context,
                  onDistribute: _distributeStock,
                ),
              ),
              onShowBatchPriceUpdate: () => _showDialog(
                context,
                BatchActionDialogs.batchPriceUpdateDialog(
                  context,
                  onUpdatePrices: _batchUpdatePrices,
                ),
              ),
              onShowBatchDiscount: () => _showDialog(
                context,
                BatchActionDialogs.batchDiscountDialog(
                  context,
                  onUpdateDiscounts: _batchUpdateDiscounts,
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacingMedium),
            Divider(
              color: isDark ? AppTheme.dividerColor : Colors.grey.shade300,
            ),
            SizedBox(height: AppTheme.spacingSmall),

            // Filter stats and clear button
            FilterStatsHeader(
              totalVariants: _localVariants.length,
              displayedVariants: displayVariants.length,
              hasFilters: _selectedSize != null || _selectedColor != null,
              onClearFilters: () {
                setState(() {
                  _selectedColor = null;
                  _selectedSize = null;
                });
              },
            ),

            // Main data table
            VariationTableBody(
              variations: widget.variations,
              variants: displayVariants,
              allVariants: _localVariants,
              basePrice: widget.basePrice,
              editingPrice: _editingPrice,
              editingStock: _editingStock,
              editingSku: _editingSku,
              editingDiscount: _editingDiscount,
              onToggleEditingPrice: () =>
                  setState(() => _editingPrice = !_editingPrice),
              onToggleEditingStock: () =>
                  setState(() => _editingStock = !_editingStock),
              onToggleEditingSku: () =>
                  setState(() => _editingSku = !_editingSku),
              onToggleEditingDiscount: () =>
                  setState(() => _editingDiscount = !_editingDiscount),
              onUpdateVariant: _updateVariant,
            ),

            if (displayVariants.isEmpty)
              Text(
                "No variants to display",
                style: TextStyle(color: AppTheme.negative),
              ),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, Widget dialog) {
    showDialog(context: context, builder: (context) => dialog);
  }
}
