
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_details/product_details_bloc.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_list/product_list_bloc.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_forms/product_update_page.dart';

class ProductActionsHandler {
  static Future<void> navigateToEditPage(BuildContext context, ProductEntity product) async {
   final result = await Navigator.of(context).push(
     MaterialPageRoute(
       builder: (context) => ProductUpdatePage(product: product),
      ),
   );

   if (result == true && context.mounted) {
      context.read<ProductsListBloc>().add( GetPaginatedProductsEvent(page: 1,pageSize: 20));

      context.read<ProductDetailBloc>().add(GetProductByIdEvent(product.id));
    }
  }

  static void showDeleteConfirmation(BuildContext context, ProductEntity product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductDetailBloc>().add(
                    DeleteProductEvent(productId: product.id),
                  );

              context.read<ProductsListBloc>().add(
                    ProductDeletedEvent(productId: product.id),
                  );

              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
