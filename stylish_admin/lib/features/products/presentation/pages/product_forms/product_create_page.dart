
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_details/product_details_bloc.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_form_widgets/product_create_form.dart';

class ProductCreatePage extends StatelessWidget {
  const ProductCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ProductCreateForm(
              onSave: (product, images) async {
           
                try {
                  context.read<ProductDetailBloc>().add(
                        CreateProductEvent(
                          product: product,
                          images: images,
                        ),
                      );
                  return product;
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
