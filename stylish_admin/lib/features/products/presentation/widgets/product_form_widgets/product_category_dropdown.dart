
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/features/category/presentation/bloc/category_bloc.dart';

class ProductCategoryDropdown extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String?, String?) onCategoryChanged;

  const ProductCategoryDropdown({
    super.key,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoaded) {
          if (state.categories.isEmpty) {
            return const Text('No categories available');
          }

          final categoryExists = selectedCategoryId != null && 
                                state.categories.any((category) => category.id == selectedCategoryId);
          
          // Create dropdown items
          final dropdownItems = state.categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList();

          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
            ),
            value: categoryExists ? selectedCategoryId : null,
            items: dropdownItems,
            onChanged: (value) {
              if (value != null) {
                // Find category in the list without using firstWhere
                String categoryName = 'Unknown Category';
                for (final category in state.categories) {
                  if (category.id == value) {
                    categoryName = category.name;
                    break;
                  }
                }
                
                onCategoryChanged(value, categoryName);
              } else {
                onCategoryChanged(null, null);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        } else if (state is CategoriesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to load categories'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  context.read<CategoryBloc>().add(LoadCategoriesEvent());
                },
                child: const Text('Retry'),
              ),
            ],
          );
        }
      },
    );
  }
}
