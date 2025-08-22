
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

class ProductCreateForm extends StatefulWidget {
  final Future<ProductEntity?> Function(ProductEntity, List<dynamic>) onSave;

  const ProductCreateForm({
    super.key,
    required this.onSave,
  });

  @override
  State<ProductCreateForm> createState() => _ProductCreateFormState();
}

class _ProductCreateFormState extends State<ProductCreateForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _initialStockController;
  late TextEditingController _costController;
  late TextEditingController _profitMarginController;
  late TextEditingController _sizesController;

  // Product data
  ProductCategory? _selectedCategory;
  bool _isActive = true;
  bool _isSaving = false;
  final Map<String, List<String>> _variations = {};
  List<ProductVariantEntity> _variants = [];

  late String? _selectedCategoryId;
  late String? _selectedCategoryName;
  final List<String> _sizes = [];

  // Image handling
  final List<dynamic> _imageFiles = [];
  final List<String> _imageUrls = [];
  final List<bool> _isPrimaryFlags = [];
  ProductImageEntity? _primaryImage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _selectedCategory = const ProductCategory(id: '', name: '');
    _selectedCategoryId = '';
    _selectedCategoryName = '';
    // Load categories when the page initializes
    context.read<CategoryBloc>().add(LoadCategoriesEvent());
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _discountPriceController = TextEditingController();
    _initialStockController = TextEditingController(text: '0');
    _costController = TextEditingController();
    _profitMarginController = TextEditingController();
    _sizesController = TextEditingController();
  }

  List<ProductVariationsEntity> _convertMapToVariations(
      Map<String, List<String>> variationsMap) {
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

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Check if category is selected
      if ((_selectedCategory == null || _selectedCategory!.id.isEmpty) &&
          (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)) {
        _showErrorMessage('Please select a product category');
        return;
      }

      if (_nameController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _priceController.text.isEmpty ||
          _costController.text.isEmpty ||
          (_selectedCategory == null && _selectedCategoryId == null)) {
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
        // Check if we have at least one image
        if (_imageUrls.isEmpty) {
          _showErrorMessage('Please add at least one product image');
          setState(() {
            _isSaving = false;
          });
          return;
        }

        final primaryImageIndex =
            _isPrimaryFlags.isNotEmpty && _isPrimaryFlags.contains(true)
                ? _isPrimaryFlags.indexOf(true)
                : (_isPrimaryFlags.isNotEmpty ? 0 : -1);

        List<ProductImageEntity> productImages = [];
        for (int i = 0; i < _imageUrls.length; i++) {
          productImages.add(
            ProductImageEntity(
              id: i.toString(), 
              productId: null,
              imageUrl: _imageUrls[i],
              altText: 'Product Image ${i + 1}',
              order: i,
              isPrimary: _isPrimaryFlags[i],
              createdAt: DateTime.now(),
            ),
          );
        }

        List<ProductVariationsEntity> productVariations =
            _convertMapToVariations(_variations);

        ProductImageEntity? primaryImage =
            (primaryImageIndex >= 0 && primaryImageIndex < productImages.length)
                ? productImages[primaryImageIndex]
                : null;

        final double priceValue = double.parse(_priceController.text);
        final double? costValue = _costController.text.isNotEmpty
            ? double.parse(_costController.text)
            : null;
        final double? discountPriceValue =
            _discountPriceController.text.isNotEmpty
                ? double.parse(_discountPriceController.text)
                : null;

        final int initialStock = int.parse(_initialStockController.text);

        final MoneyEntity price = MoneyEntity(value: priceValue);
        final MoneyEntity? cost = costValue != null ? MoneyEntity(value: costValue) : null;
        final MoneyEntity? discountPrice = discountPriceValue != null
            ? MoneyEntity(value: discountPriceValue)
            : null;

        final Rating rating = Rating(value: 0.0, count: 0);

        final ProductEntity productData = ProductEntity(
          id: '', 
          name: _nameController.text,
          description: _descriptionController.text,
          category: ProductCategory(
            id: (_selectedCategory != null && _selectedCategory!.id.isNotEmpty)
                ? _selectedCategory!.id
                : _selectedCategoryId ?? '',
            name: _selectedCategoryName ?? '',
          ),
          price: price,
          cost: cost,
          discountPrice: discountPrice,
          stock: initialStock,
          initialStock: initialStock,
          images: productImages,
          primaryImage: primaryImage,
          variations: productVariations,
          variants: _variants,
          rating: rating,
          stockStatus: initialStock > 0
              ? (initialStock < 10 ? StockStatus.lowStock : StockStatus.inStock)
              : StockStatus.outOfStock,
          isActive: _isActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        List<dynamic> imagesForUpload = _prepareImagesForUpload();

        final savedProduct = await widget.onSave(productData, imagesForUpload);

        if (savedProduct != null) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Product created successfully'),
              action: SnackBarAction(
                label: 'Manage Variations',
                onPressed: () {
                  sl<NavigationService>().pushNamed(
                    RouteNames.productVariations,
                    arguments: {
                      'productId': savedProduct.id,
                      'variations': _convertMapToVariations(_variations),
                      'variants': _variants,
                    },
                  );
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );

          Navigator.pop(context, true);
        } else {
          setState(() {
            _isSaving = false;
          });
          _showErrorMessage('Failed to create product');
        }
      } catch (e) {
        print('Exception in _saveProduct: $e');
        _showErrorMessage('Error saving product: $e');
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _initialStockController.dispose();
    _costController.dispose();
    _profitMarginController.dispose();
    _sizesController.dispose();
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
          Text(
            'Add New Product',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          // Product Images
          ProductImageSection(
            initialImageUrls: _imageUrls,
            initialIsPrimaryFlags: _isPrimaryFlags,
            primaryImageUrl: _primaryImage?.imageUrl,
            onImagesChanged: (files, urls, primaries, primaryUrl) {
              setState(() {
                _imageFiles.clear();
                _imageFiles.addAll(files);
                _imageUrls.clear();
                _imageUrls.addAll(urls);
                _isPrimaryFlags.clear();
                _isPrimaryFlags.addAll(primaries);
                _primaryImage = primaryUrl != null
                    ? ProductImageEntity(
                        id: 'temp',
                        imageUrl: primaryUrl,
                        altText: 'Primary Image',
                        order: 0,
                        isPrimary: true,
                        createdAt: DateTime.now(),
                      )
                    : null;
              });
            },
          ),
          const SizedBox(height: 24),

          // Initial Stock Card
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Initial Inventory',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _initialStockController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Stock',
                      helperText: 'Starting quantity for this product',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter initial stock';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You can manage detailed inventory after product creation',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
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
            stockController: _initialStockController,
            costController: _costController,
            initialStockController: _initialStockController,
            sizesController: _sizesController,
            profitMarginController: _profitMarginController,
            selectedCategoryId: _selectedCategoryId,
            selectedCategoryName: _selectedCategoryName,
            sizes: _sizes,
            variations: _variations,
            variants: _variants,
            productId: null, 
            isActive: _isActive,
            isUpdateMode: false,
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
            onVariantsChanged: (variants) {
              setState(() {
                _variants = variants;
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
          const SizedBox(height: 24),

          ProductActionButtons(
            isSaving: _isSaving,
            isNewProduct: true,
            onSave: _saveProduct,
          ),
        ],
      ),
    );
  }
}
