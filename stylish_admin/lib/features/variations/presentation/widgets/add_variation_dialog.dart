import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class AddVariationDialog extends StatefulWidget {
  final Function(String, List<String>) onAddVariation;
  const AddVariationDialog({super.key, required this.onAddVariation});

  @override
  State<AddVariationDialog> createState() => _AddVariationDialogState();
}

class _AddVariationDialogState extends State<AddVariationDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final List<String> values = [];
  final _formKey = GlobalKey<FormState>();

  void _addValue() {
    final value = valueController.text.trim();
    if (value.isNotEmpty && !values.contains(value)) {
      setState(() {
        values.add(value);
        valueController.clear();
      });
    } else if (values.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Value already exists'),
          backgroundColor: AppTheme.negative,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          margin: EdgeInsets.all(AppTheme.spacingMedium),
        ),
      );
    }
  }

  void _removeValue(String value) {
    setState(() {
      values.remove(value);
    });
  }

  void _saveVariation() {
    if (_formKey.currentState!.validate()) {
      final name = nameController.text.trim();

      if (values.isNotEmpty) {
        widget.onAddVariation(name, List.from(values));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add at least one value'),
            backgroundColor: AppTheme.negative,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            margin: EdgeInsets.all(AppTheme.spacingMedium),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        constraints: BoxConstraints(minHeight: 300, maxWidth: 480),
        padding: EdgeInsets.all(AppTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.textSecondary,
                    size: 28,
                  ),
                  SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    'Add Variation',
                    style: AppTheme.headingMedium().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20),
                    splashRadius: 20,
                    tooltip: 'Close',
                  ),
                ],
              ),

              Divider(height: AppTheme.spacingLarge),
              SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: nameController,
                style: AppTheme.bodyMedium(),
                decoration: InputDecoration(
                  labelText: 'Variation name',
                  hintText: 'e.g., Color, Size, Material',
                  labelStyle: AppTheme.bodyMedium().copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                    borderSide: BorderSide(
                      color: AppTheme.primaryLight,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentEmerald,
                  prefixIcon: Icon(
                    Icons.category,
                    color: AppTheme.textSecondary,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingMedium,
                  ),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a variation name';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: valueController,
                      style: AppTheme.bodyMedium(),
                      decoration: InputDecoration(
                        labelText: 'Value',
                        hintText: 'e.g., Red, Large, Cotton',
                        labelStyle: AppTheme.bodyMedium().copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                          borderSide: BorderSide(
                            color: AppTheme.primaryLight,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.accentEmerald,
                        prefixIcon: Icon(
                          Icons.label_outline,
                          color: AppTheme.textSecondary,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMedium,
                          vertical: AppTheme.spacingMedium,
                        ),
                      ),

                      onFieldSubmitted: (value) => _addValue(),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMedium),
                  ElevatedButton.icon(
                    onPressed: _addValue,
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.accentIvory,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.spacingMedium,
                        horizontal: AppTheme.spacingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppTheme.spacingMedium),
              if (values.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.list, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: AppTheme.spacingXSmall),
                    Text(
                      'Values: ',
                      style: AppTheme.bodyMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '(${values.length})',
                      style: AppTheme.bodySmall().copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppTheme.spacingSmall),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withAlpha(
                      (0.5 * 255).round(),
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                    border: Border.all(
                      color: AppTheme.borderColor.withAlpha(
                        (0.3 * 255).round(),
                      ),
                    ),
                  ),
                  padding: EdgeInsets.all(AppTheme.spacingSmall),
                  child: Wrap(
                    spacing: AppTheme.spacingSmall,
                    runSpacing: AppTheme.spacingSmall,
                    children: values.map((value) {
                      return Chip(
                        label: Text(
                          value,
                          style: AppTheme.bodySmall().copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: AppTheme.primaryLight,
                        deleteIconColor: AppTheme.textPrimary,
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeValue(value),
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacingSmall,
                          horizontal: AppTheme.spacingSmall,
                        ),
                        elevation: 1,
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withAlpha(
                      (0.5 * 255).round(),
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                    border: Border.all(
                      color: AppTheme.borderColor.withAlpha(
                        (0.3 * 255).round(),
                      ),
                    ),
                  ),

                  child: Center(
                    child: Text(
                      'No values added yet',
                      style: AppTheme.bodyMedium().copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: AppTheme.spacingLarge),
              Divider(height: 1),
              SizedBox(height: AppTheme.spacingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                        vertical: AppTheme.spacingSmall,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTheme.bodyMedium().copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMedium),
                  ElevatedButton(
                    onPressed: _saveVariation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: AppTheme.textPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                        vertical: AppTheme.spacingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Save Variation',
                      style: AppTheme.bodyMedium().copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
