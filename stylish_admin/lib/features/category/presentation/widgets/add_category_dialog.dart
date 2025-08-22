
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/utils/web_image_utils.dart';
import 'package:stylish_admin/features/category/presentation/bloc/category_bloc.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  String? _selectedParentId;
  bool _isValidating = false;
  bool _hasNameError = false;
  String? _nameErrorText;
  
  Uint8List? _imageFile;
  String? _imageUrl;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.forward();

    _nameController.addListener(_validateNameDebounced);
  }

  void _validateNameDebounced() {
    if (_nameController.text.isNotEmpty) {
      if (!_isValidating) {
        _isValidating = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _validateName();
            _isValidating = false;
          }
        });
      }
    } else {
      if (_hasNameError) {
        setState(() {
          _hasNameError = false;
          _nameErrorText = null;
        });
      }
    }
  }

  void _validateName() {
    if (_nameController.text.isEmpty) {
      setState(() {
        _hasNameError = true;
        _nameErrorText = 'Category name cannot be empty';
      });
      return;
    }

    BlocProvider.of<CategoryBloc>(context).add(
      ValidateCategoryNameEvent(
        name: _nameController.text,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final bytes = result.files.first.bytes!;
        
        if (!WebImageUtils.validateImageSize(bytes)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size exceeds the 2MB limit')),
          );
          return;
        }
        
        final mimeType = 'image/${result.files.first.extension?.toLowerCase() ?? 'jpeg'}';
        final dataUrl = WebImageUtils.encodeToDataUrl(bytes, mimeType);

        setState(() {
          _imageFile = bytes;
          _imageUrl = dataUrl;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageUrl = null;
    });
  }

  @override
Widget build(BuildContext context) {
  return BlocListener<CategoryBloc, CategoryState>(
    listener: (context, state) {
      if (state is CategoryNameError) {
        setState(() {
          _hasNameError = true;
          _nameErrorText = state.message;
        });
      } else if (state is CategoryNameValid) {
        setState(() {
          _hasNameError = false;
          _nameErrorText = null;
        });
      } else if (state is CategoryCreated) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "${state.category.name}" created successfully')),
        );
      }
    },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Add New Category',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a new product category',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildNameField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildParentCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildImagePicker(),
                  const SizedBox(height: 16),
                  _buildActiveSwitch(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Cancel'),
            ),
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                final isLoading = state is CategoriesLoading;
                return ElevatedButton.icon(
                  icon: isLoading 
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.save),
                  label: Text(isLoading ? 'Creating...' : 'Create Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (_hasNameError || isLoading) ? null : _submitForm,
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Category Name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.label),
        filled: true,
        fillColor: Colors.white.withAlpha((0.05*255).round()),
        errorText: _hasNameError ? _nameErrorText : null,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: 'Enter a unique category name',
        hintStyle: TextStyle(color: Colors.white.withAlpha((0.3*255).round())),
      ),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name';
        }
        if (_hasNameError) {
          return _nameErrorText;
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.description),
        filled: true,
        fillColor: Colors.white.withAlpha((0.05*255).round()),
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: 'Enter a description (optional)',
        hintStyle: TextStyle(color: Colors.white.withAlpha((0.3*255).round())),
      ),
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
    );
  }

  Widget _buildParentCategoryDropdown() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoaded) {
          final parentOptions = [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None (Root Category)',
                  style: TextStyle(color: Colors.white)),
            ),
            ...state.categories.map((category) {
              return DropdownMenuItem<String?>(
                value: category.id,
                child: Text(category.name,
                    style: const TextStyle(color: Colors.white)),
              );
            }),
          ];

          return DropdownButtonFormField<String?>(
            value: _selectedParentId,
            decoration: InputDecoration(
              labelText: 'Parent Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.account_tree),
              filled: true,
              fillColor: Colors.white.withAlpha((0.05*255).round()),
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white.withAlpha((0.3*255).round())),
            ),
            dropdownColor: const Color(0xFF16213E),
            style: const TextStyle(color: Colors.white),
            items: parentOptions,
            onChanged: (value) {
              setState(() {
                _selectedParentId = value;
              });
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Image',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (_imageUrl != null)
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _removeImage,
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white30, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate, color: Colors.blue, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Click to add an image',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Row(
      children: [
        const Icon(
          Icons.visibility,
          color: Colors.white70,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Active Category',
            style: TextStyle(color: Colors.white),
          ),
        ),
        Switch(
          value: _isActive,
          activeColor: Colors.blue,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic>? imageData;
      
      if (_imageFile != null && _imageUrl != null) {
        imageData = {
          'data': _imageUrl,
          'name': 'category_image.jpg',
          'is_primary': true,
        };
      }

      BlocProvider.of<CategoryBloc>(context).add(
        CreateCategoryEvent(
          name: _nameController.text,
          description: _descriptionController.text,
          parentId: _selectedParentId,
          isActive: _isActive,
          image: imageData,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animController.dispose();
    super.dispose();
  }
}