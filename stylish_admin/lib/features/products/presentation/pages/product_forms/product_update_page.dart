import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_details/product_details_bloc.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_form_widgets/product_update_form.dart';

class ProductUpdatePage extends StatelessWidget {
  final ProductEntity product;
  const ProductUpdatePage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ProductUpdateForm(
              product: product,
              onSave: (productData, imagesForUpload) async {
                try {
                  context.read<ProductDetailBloc>().add(
                    UpdateProductEvent(
                      product: product,
                      newImages: imagesForUpload,
                      id: product.id,
                    ),
                  );
                  return productData;
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return null;
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
