import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/products/presentation/bloc/product_list/product_list_bloc.dart';
import 'package:stylish_admin/features/products/presentation/pages/product_forms/product_create_page.dart';

class ProductsEmptyState extends StatelessWidget {
  const ProductsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'No products found',
            style: AppTheme.headingMedium().copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          ElevatedButton(
            onPressed: () => _navigateToAddProductPage(context),
            child: const Text('Add Your First Product'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProductPage(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductCreatePage(),
      ),
    );

    if (result == true && context.mounted) {
     context.read<ProductsListBloc>().add( GetPaginatedProductsEvent(page: 1, pageSize: 20));
   }
  }
}