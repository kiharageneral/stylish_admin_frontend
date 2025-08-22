import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class UpdateStockDialog extends StatefulWidget {
  final Function(int) onUpdateStock;
  final int currentStock;
  const UpdateStockDialog({
    super.key,
    required this.onUpdateStock,
    this.currentStock = 0,
  });

  @override
  State<UpdateStockDialog> createState() => _UpdateStockDialogState();
}

class _UpdateStockDialogState extends State<UpdateStockDialog> {
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController();
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Stock for All Variants'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Total Stock: ${widget.currentStock}',
            style: AppTheme.bodyMedium().copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Enter the new stock level for all variants:'),
          SizedBox(height: 8),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'New Stock Quantity',
              border: OutlineInputBorder(),
              hintText: 'Enter quantity',
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final int? newStock = int.tryParse(_stockController.text);
            if (newStock != null) {
              widget.onUpdateStock(newStock);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: AppTheme.textPrimary,
          ),
          child: Text('Update'),
        ),
      ],
    );
  }
}
