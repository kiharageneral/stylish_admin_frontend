import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/di/injection_container.dart';
import 'package:stylish_admin/core/routes/route_names.dart';
import 'package:stylish_admin/core/service/navigation_service.dart';
import 'package:stylish_admin/core/utils/web_image_utils.dart';
import 'package:stylish_admin/features/category/presentation/bloc/category_bloc.dart';
import 'package:stylish_admin/features/products/domain/entities/money_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/product_image_entity.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_form_widgets/product_actions_button.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_form_widgets/product_form_fields.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_images/product_image_section.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variations_entity.dart';

class ProductUpdateForm extends StatefulWidget {
  final ProductEntity product;
  final Future<ProductEntity?> Function(ProductEntity, List<dynamic>) onSave;

  const ProductUpdateForm({
    super.key,
    required this.product,
    required this.onSave,
  });

  @override
  State<ProductUpdateForm> createState() => _ProductUpdateFormState();
}

class _ProductUpdateFormState extends State<ProductUpdateForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _stockController;
  late TextEditingController _ratingValueController;
  late TextEditingController _ratingCountController;
  late TextEditingController _initialStockController;
  late TextEditingController _costController;
  late TextEditingController _profitMarginController;
  late TextEditingController _sizesController;
  late TextEditingController _reorderPointController;

  // Product data
  bool _isActive = true;
  bool _isSaving = false;
  Map<String, List<String>> _variations = {};
  List<ProductVariantEntity> _variants = [];
  late String _productId;
  StockStatus _stockStatus = StockStatus.inStock;

  late String? _selectedCategoryId;
  late String? _selectedCategoryName;
  final List<String> _sizes = [];

  // Image handling
  late List<dynamic> _imageFiles = [];
  late List<String> _imageUrls = [];
  late List<bool> _isPrimaryFlags = [];
  ProductImageEntity? _primaryImage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingProductData();
    _variants = widget.product.variants;
    _productId = widget.product.id;
    _selectedCategoryId = widget.product.category.id;
    _selectedCategoryName = widget.product.category.name;
    _variations = _convertVariationsToMap(widget.product.variations);
    context.read<CategoryBloc>().add(LoadCategoriesEvent());
  }

  Map<String, List<String>> _convertVariationsToMap(
    List<ProductVariationsEntity> variationsList,
  ) {
    final Map<String, List<String>> variationsMap = {};
    for (var variation in variationsList) {
      variationsMap[variation.name] = variation.values;
    }
    return variationsMap;
  }

  List<ProductVariationsEntity> _convertMapToVariations(
    Map<String, List<String>> variationsMap,
  ) {
    final List<ProductVariationsEntity> variationsList = [];
    variationsMap.forEach((name, values) {
      variationsList.add(
        ProductVariationsEntity(
          id: name.toLowerCase().replaceAll(' ', '_'),
          name: name,
          values: values,
        ),
      );
    });
    return variationsList;
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _priceController = TextEditingController(
      text: widget.product.price.value.toString(),
    );
    _discountPriceController = TextEditingController(
      text: widget.product.discountPrice?.value.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
    _ratingValueController = TextEditingController(
      text: widget.product.rating.value.toString(),
    );
    _ratingCountController = TextEditingController(
      text: widget.product.rating.count.toString(),
    );
    _initialStockController = TextEditingController(
      text: widget.product.initialStock.toString(),
    );
    _costController = TextEditingController(
      text: widget.product.cost?.value.toString() ?? '',
    );
    _profitMarginController = TextEditingController(
      text: widget.product.profitMargin?.toString() ?? '',
    );
    _sizesController = TextEditingController();
    _reorderPointController = TextEditingController(text: '10');
  }

  void _loadExistingProductData() {
    _isActive = widget.product.isActive;
    _stockStatus = widget.product.stockStatus;
    _primaryImage = widget.product.primaryImage;

    _variations = _convertVariationsToMap(widget.product.variations);

    _loadProductImages();

    final stock = widget.product.stock;
    _stockStatus = widget.product.stockStatus;

    if (stock < 10 && _stockStatus == StockStatus.inStock) {
      _stockStatus = StockStatus.lowStock;
    }
    _stockStatus = StockStatus.inStock;
  }

  void _loadProductImages() {
    if (widget.product.images.isNotEmpty) {
      _imageUrls.clear();
      _isPrimaryFlags.clear();
      _imageFiles.clear();

      for (var img in widget.product.images) {
        _imageUrls.add(img.imageUrl);
        _isPrimaryFlags.add(img.isPrimary);
        _imageFiles.add(null);
      }

      if (_primaryImage != null) {
        final primaryIndex = widget.product.images.indexOf(_primaryImage!);
        if (primaryIndex != -1) {
          for (int i = 0; i < _isPrimaryFlags.length; i++) {
            _isPrimaryFlags[i] = (i == primaryIndex);
          }
        }
      }

      if (_imageUrls.isNotEmpty && !_isPrimaryFlags.contains(true)) {
        _isPrimaryFlags[0] = true;
      }
    }
  }

  void _calculateProfitMargin() {
    if (_priceController.text.isNotEmpty && _costController.text.isNotEmpty) {
      try {
        final double price = double.parse(_priceController.text);
        final double cost = double.parse(_costController.text);

        if (cost > 0 && price > 0) {
          final double margin = ((price - cost) / price) * 100;
          _profitMarginController.text = margin.toStringAsFixed(2);
        }
      } catch (e) {
        print('Error calculating profit margin: $e');
      }
    }
  }

  void _addSize(String size) {
    if (size.isNotEmpty && !_sizes.contains(size)) {
      setState(() {
        _sizes.add(size);
        _sizesController.clear();
      });
    }
  }

  void _navigateToStockManagement() {
    // sl<NavigationService>().pushNamed(
    //   RouteNames.inventoryAdjustment,
    //   arguments: {
    //     'productId': _productId,
    //     'productName': _nameController.text,
    //     'currentStock': int.tryParse(_stockController.text) ?? 0,
    //   },
    // );
  }

  void _navigateToVariationsManagement() {
    sl<NavigationService>().pushNamed(
      RouteNames.productVariations,
      arguments: {
        'productId': _productId,
        'variations': _variations,
        'variants': _variants,
        'basePrice': double.tryParse(_priceController.text) ?? 0,
        'currentStock': int.tryParse(_stockController.text) ?? 0,
        'size': _sizes ?? [],
      },
    );
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
        _showErrorMessage('Please select a product category');
        return;
      }

      if (_nameController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _priceController.text.isEmpty ||
          _costController.text.isEmpty) {
        _showErrorMessage('Please fill all required fields');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        if (_imageUrls.isEmpty) {
          _showErrorMessage('Please add at least one product image');
          setState(() {
            _isSaving = false;
          });
          return;
        }

        final primaryImageIndex = _isPrimaryFlags.contains(true)
            ? _isPrimaryFlags.indexOf(true)
            : (_isPrimaryFlags.isNotEmpty ? 0 : -1);

        List<ProductImageEntity> productImages = [];

        for (int i = 0; i < _imageUrls.length; i++) {
          if (_imageUrls[i].startsWith('http')) {
            String imageId = '0';

            for (var existingImg in widget.product.images) {
              if (existingImg.imageUrl == _imageUrls[i]) {
                imageId = existingImg.id;
                break;
              }
            }

            productImages.add(
              ProductImageEntity(
                id: imageId,
                productId: _productId,
                imageUrl: _imageUrls[i],
                altText: 'Product Image ${i + 1}',
                order: i,
                isPrimary: _isPrimaryFlags[i],
                createdAt: DateTime.now(),
              ),
            );
          }
        }

        _convertMapToVariations(_variations);

        ProductImageEntity? primaryImage =
            (primaryImageIndex >= 0 && primaryImageIndex < productImages.length)
            ? productImages[primaryImageIndex]
            : null;

        double.parse(_priceController.text);

        final int stock = widget.product.stock;
        int.parse(_initialStockController.text);

        double.parse(_ratingValueController.text);
        int.parse(_ratingCountController.text);

        StockStatus stockStatus = _stockStatus;
        if (stock < 10 && stockStatus == StockStatus.inStock) {
          stockStatus = StockStatus.lowStock;
        }

        final ProductEntity updatedProduct = ProductEntity(
          id: _productId,
          name: _nameController.text,
          description: _descriptionController.text,
          category: ProductCategory(
            id: _selectedCategoryId ?? '',
            name: _selectedCategoryName ?? '',
          ),
          price: MoneyEntity(value: double.parse(_priceController.text)),
          cost: _costController.text.isNotEmpty
              ? MoneyEntity(value: double.parse(_costController.text))
              : null,
          discountPrice: _discountPriceController.text.isNotEmpty
              ? MoneyEntity(value: double.parse(_discountPriceController.text))
              : null,
          stock: widget.product.stock,
          initialStock: int.parse(_initialStockController.text),
          images: productImages,
          primaryImage: primaryImage,
          variations: widget.product.variations,
          rating: Rating(
            value: double.parse(_ratingValueController.text),
            count: int.parse(_ratingCountController.text),
          ),
          stockStatus: _stockStatus,
          isActive: _isActive,
          createdAt: widget.product.createdAt,
          updatedAt: DateTime.now(),
        );

        List<dynamic> imagesForUpload = _prepareImagesForUpload();

        final savedProduct = await widget.onSave(
          updatedProduct,
          imagesForUpload,
        );

        if (savedProduct != null) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Product updated successfully'),
              action: SnackBarAction(
                label: 'Manage Stock',
                onPressed: _navigateToStockManagement,
              ),
              duration: const Duration(seconds: 5),
            ),
          );

          Navigator.pop(context, true);
        } else {
          setState(() {
            _isSaving = false;
          });
          _showErrorMessage('Failed to update product');
        }
      } catch (e) {
        print('Exception in _updateProduct: $e');
        _showErrorMessage('Error updating product: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  List<Map<String, dynamic>> _prepareImagesForUpload() {
    return WebImageUtils.prepareImagesForUpload(
      imageUrls: _imageUrls,
      isPrimaryFlags: _isPrimaryFlags,
      productName: _nameController.text,
    );
  }

  Widget _buildStockStatusChip(StockStatus status) {
    Color chipColor;
    IconData iconData;

    switch (status) {
      case StockStatus.inStock:
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case StockStatus.lowStock:
        chipColor = Colors.orange;
        iconData = Icons.warning;
        break;
      case StockStatus.outOfStock:
        chipColor = Colors.red;
        iconData = Icons.error;
        break;
    }

    return Chip(
      avatar: Icon(iconData, color: Colors.white, size: 16),
      label: Text(
        status.displayName,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _ratingValueController.dispose();
    _ratingCountController.dispose();
    _initialStockController.dispose();
    _costController.dispose();
    _profitMarginController.dispose();
    _sizesController.dispose();
    _reorderPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Product',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.inventory),
                    tooltip: 'Manage Inventory',
                    onPressed: _navigateToStockManagement,
                  ),
                  //
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ProductImageSection(
            initialImageUrls: _imageUrls,
            initialIsPrimaryFlags: _isPrimaryFlags,
            primaryImageUrl: _primaryImage?.imageUrl,
            onImagesChanged: (files, urls, primaries, primaryUrl) {
              setState(() {
                _imageFiles = List.from(files);
                _imageUrls = List.from(urls);
                _isPrimaryFlags = List.from(primaries);

                if (primaryUrl != null) {
                  final primaryIndex = _imageUrls.indexOf(primaryUrl);
                  if (primaryIndex != -1) {
                    _primaryImage = ProductImageEntity(
                      id: primaryIndex.toString(),
                      productId: _productId,
                      imageUrl: primaryUrl,
                      altText: 'Primary Image',
                      order: primaryIndex,
                      isPrimary: true,
                      createdAt: DateTime.now(),
                    );
                  }
                } else {
                  _primaryImage = null;
                }
              });
            },
          ),
          const SizedBox(height: 24),

          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inventory Management',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      _buildStockStatusChip(_stockStatus),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(
                            labelText: 'Current Stock',
                            helperText: 'Manage in inventory section',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _initialStockController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Starting Inventory',
                            border: OutlineInputBorder(),
                            helperText: 'Set at creation',
                            prefixIcon: Icon(Icons.add_shopping_cart),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Reorder point field
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _reorderPointController,
                          decoration: const InputDecoration(
                            labelText: 'Reorder Point',
                            border: OutlineInputBorder(),
                            helperText: 'Inventory alert threshold',
                            prefixIcon: Icon(Icons.warning_amber),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.inventory_2),
                      label: const Text('Manage Stock History & Adjustments'),
                      onPressed: _navigateToStockManagement,
                    ),
                  ),
                ],
              ),
            ),
          ),

          ProductFormFields(
            nameController: _nameController,
            descriptionController: _descriptionController,
            priceController: _priceController,
            discountPriceController: _discountPriceController,
            stockController: _stockController,
            costController: _costController,
            initialStockController: _initialStockController,
            sizesController: _sizesController,
            profitMarginController: _profitMarginController,
            selectedCategoryId: _selectedCategoryId,
            selectedCategoryName: _selectedCategoryName,
            sizes: _sizes,
            variations: _variations,
            isActive: _isActive,
            variants: _variants,
            productId: _productId,
            isUpdateMode: true,
            onVariantsChanged: (variants) {
              setState(() {
                _variants = variants;
              });
            },
            onCalculateProfitMargin: _calculateProfitMargin,
            onSizeAdded: _addSize,
            onCategoryChanged: (id, name) {
              setState(() {
                _selectedCategoryId = id;
                _selectedCategoryName = name;
              });
            },
            onVariationsChanged: (variations) {
              setState(() {
                _variations.clear();
                _variations.addAll(variations);
              });
            },
            onSizesChanged: (sizes) {
              setState(() {
                _sizes.clear();
                _sizes.addAll(sizes);
              });
            },
            onActiveChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),

          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _productId.isEmpty
                ? null
                : _navigateToVariationsManagement,
            icon: const Icon(Icons.tune),
            label: const Text('Manage Variations'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          ProductActionButtons(
            isSaving: _isSaving,
            isNewProduct: false,
            onSave: _updateProduct,
          ),
        ],
      ),
    );
  }
}
