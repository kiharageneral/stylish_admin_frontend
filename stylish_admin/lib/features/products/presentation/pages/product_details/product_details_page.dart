import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/event_bus/app_event_bus.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_details/product_details_bloc.dart';
import 'package:stylish_admin/features/products/presentation/pages/components/product_actions_handler.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_details/components/product_details_header.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_details/components/product_image_section.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_details/components/product_infor_section.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_details/components/product_tabs_section.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductEntity product;
  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late ProductEntity _currentProduct;
  StreamSubscription<ProductDetailState>? _productSubscription;
  ProductDetailBloc? _productDetailBloc;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _productDetailBloc = BlocProvider.of<ProductDetailBloc>(context);

    if (_productSubscription == null) {
      _setupBlocListener();
      _loadProductDetails();
      _setupEventBusListener();
    }
  }

  StreamSubscription<AppEvent>? _eventBusSubscription;

  void _setupEventBusListener() {
    _eventBusSubscription = AppEventBus().events.listen((event) {
      if (event is ProductUpdatedEvent && event.product.id == _currentProduct.id) {
        setState(() {
          _currentProduct = event.product;
        });
      }else if(event is ProductRemovedEvent && event.productId == _currentProduct.id) {
        Navigator.pop(context);
      }
     } 
    );
  }

  void _loadProductDetails() {
    if (_productDetailBloc != null) {
      _productDetailBloc!.add(GetProductByIdEvent(_currentProduct.id));
    }
  }
  void _setupBlocListener() {
    if(_productDetailBloc != null) {
      _productSubscription = _productDetailBloc!.stream.listen((state){
        if(state.product != null && state.product!.id == widget.product.id) {
          if(mounted) {
            setState(() {
              _currentProduct = state.product!;
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _productSubscription = null;
    _productDetailBloc = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductDetailBloc, ProductDetailState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!, style: AppTheme.bodyMedium()),
              backgroundColor: AppTheme.negative,
            ),
          );
        } else if (state.isOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Operation completed successfully.",
                style: AppTheme.bodyMedium(),
              ),
              backgroundColor: AppTheme.success,
            ),
          );
        }

        if (state.isOperationSuccess && state.product == null) {
          Navigator.pop(context);
        }
      },
      child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductDetailsHeader(
                  product: _currentProduct,
                  onEditPressed: _handleEditProduct,
                  onDeletePressed: _handleDeleteProduct,
                ),
                _buildConstrainedContentContainer(context),
                 ProductTabsSection(product:_currentProduct),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConstrainedContentContainer(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double maxContentWidth = width;

    if (width >= ResponsiveHelper.largeDesktopBreakpoint) {
      maxContentWidth = width * 0.9;
      maxContentWidth = maxContentWidth > 1600 ? 1600 : maxContentWidth;
    } else if (width >= ResponsiveHelper.desktopBreakpoint) {
      maxContentWidth = width * 0.95;
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        padding: ResponsiveHelper.getSafeHorizontalPadding(context),
        child: _buildResponsiveProductContent(context),
       
      ),
    );
  }

  Widget _buildResponsiveProductContent(BuildContext context) {
    return ResponsiveHelper.buildResponsiveLayout(
      context,
      mobile: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImagesSection(product: _currentProduct),
          const SizedBox(height: AppTheme.spacingMedium),
          ProductInfoSection(product: _currentProduct),
        ],
      ),
      tablet: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImagesSection(product: _currentProduct),
          const SizedBox(height: AppTheme.spacingMedium),
          ProductInfoSection(product: _currentProduct),
        ],
      ),
      desktop: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: ProductImagesSection(product: _currentProduct),
          ),
          const SizedBox(width: AppTheme.spacingLarge),
          Expanded(
            flex: 7,
            child: ProductInfoSection(product: _currentProduct),
          ),
        ],
      ),

      largeDesktop: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: ProductImagesSection(product: _currentProduct),
          ),
          const SizedBox(width: AppTheme.spacingLarge),
          Expanded(
            flex: 6,
            child: ProductInfoSection(product: _currentProduct),
          ),
        ],
      ),
    );
  }

  void _handleEditProduct() {
    ProductActionsHandler.navigateToEditPage(context, _currentProduct);
  }

  void _handleDeleteProduct() {
    ProductActionsHandler.showDeleteConfirmation(context, _currentProduct);
  }
}
