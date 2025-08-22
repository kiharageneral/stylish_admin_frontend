
import 'package:flutter/material.dart';

class ProductActionButtons extends StatelessWidget {
  final bool isSaving;
  final bool isNewProduct;
  final VoidCallback onSave;

  const ProductActionButtons({
    super.key,
    required this.isSaving,
    required this.isNewProduct,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(isNewProduct ? 'Add Product' : 'Save Changes'),
        ),
      ],
    );
  }
}