
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/utils/web_image_utils.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/presentation/bloc/category_bloc.dart';

class EditCategoryDialog extends StatefulWidget {
  final CategoryEntity category;

  const EditCategoryDialog({
    super.key,
    required this.category,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isActive;
  String? _selectedParentId;
  bool _hasNameError = false;
  String? _nameErrorText;
  bool _isSubmitting = false;

  Uint8List? _imageFile;
  String? _imageUrl;
  bool _isImagePrimary = true;
  bool _imageChanged = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _descriptionController =
        TextEditingController(text: widget.category.description);
    _isActive = widget.category.isActive;
    _selectedParentId = widget.category.parent;
    
    if (widget.category.image != null && widget.category.image!.isNotEmpty) {
      _imageUrl = widget.category.image;
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.forward();
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
          _isImagePrimary = true;
          _imageChanged = true;
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
      _imageChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: BlocListener<CategoryBloc, CategoryState>(
        listenWhen: (previous, current) =>
            current is CategoryNameError ||
            current is CategoryNameValid ||
            current is CategoryUpdated,
        listener: (context, state) {
          if (state is CategoryNameError) {
            setState(() {
              _hasNameError = true;
              _nameErrorText = state.message;
              _isSubmitting = false;
            });
          } else if (state is CategoryNameValid) {
            setState(() {
              _hasNameError = false;
              _nameErrorText = null;
            });
            _processFormSubmission();
          } else if (state is CategoryUpdated) {
            setState(() {
              _isSubmitting = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Category updated successfully'),
                backgroundColor: Colors.green,
              ),
            );

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.of(context)
                    .pop(true); 
              }
            });
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
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Edit ${widget.category.name}',
                  style: const TextStyle(color: Colors.white),
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
                      'Update category information',
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
                onPressed:
                    _isSubmitting ? null : () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: _isSubmitting
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitForm,
              ),
            ],
          ),
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
        fillColor: Colors.white.withAlpha((0.05 * 255).round()),
        errorText: _hasNameError ? _nameErrorText : null,
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name';
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
        fillColor: Colors.white.withAlpha((0.05 * 255).round()),
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: 'Enter a description (optional)',
        hintStyle:
            TextStyle(color: Colors.white.withAlpha((0.3 * 255).round())),
      ),
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
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
                  child: _imageFile != null
                      ? Image.memory(
                          _imageFile!,
                          fit: BoxFit.cover,
                        )
                      : _imageUrl!.startsWith('data:')
                          ? Image.memory(
                              WebImageUtils.extractBytesFromDataUrl(_imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error, color: Colors.red),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
              Positioned(
                top: 5,
                left: 5,
                child: IconButton(
                  icon: const Icon(Icons.change_circle, color: Colors.blue),
                  onPressed: _pickImage,
                  tooltip: 'Change Image',
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

  Widget _buildParentCategoryDropdown() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoaded) {
          final availableParents = state.categories
              .where((c) => c.id != widget.category.id)
              .toList();

          bool selectedParentExists = _selectedParentId == null ||
              availableParents.any((c) => c.id == _selectedParentId);

          if (!selectedParentExists) {
            _selectedParentId = null;
          }

          return DropdownButtonFormField<String?>(
            value: _selectedParentId,
            decoration: InputDecoration(
              labelText: 'Parent Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.account_tree),
              filled: true,
              fillColor: Colors.white.withAlpha((0.05 * 255).round()),
              labelStyle: const TextStyle(color: Colors.white70),
            ),
            dropdownColor: const Color(0xFF1E2A45),
            style: const TextStyle(color: Colors.white),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None (Root Category)'),
              ),
              ...availableParents.map((category) {
                return DropdownMenuItem<String?>(
                  value: category.id,
                  child: Text(category.name),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedParentId = value;
              });
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActiveSwitch() {
    return SwitchListTile(
      title: const Text(
        'Active',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Category will be visible to customers',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
      value: _isActive,
      activeColor: Colors.blue,
      onChanged: (value) {
        setState(() {
          _isActive = value;
        });
      },
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withAlpha((0.1 * 255).round())),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      if (_nameController.text != widget.category.name) {
        setState(() {
          _hasNameError = false;
          _nameErrorText = null;
        });

        BlocProvider.of<CategoryBloc>(context).add(
          ValidateCategoryNameEvent(
            name: _nameController.text,
            excludeCategoryId: widget.category.id,
          ),
        );
      } else {
        _processFormSubmission();
      }
    }
  }

  void _processFormSubmission() {
    Map<String, dynamic>? imageData;
    
    if (_imageChanged) {
      if (_imageUrl != null && _imageFile != null) {
        imageData = {
          'data': _imageUrl,
          'name': 'category_image.jpg',
          'is_primary': _isImagePrimary,
        };
      } else if (_imageUrl != null && _imageUrl!.startsWith('http')) {
        imageData = null;
      } else if (_imageUrl == null) {
        imageData = {
          'remove': true,
        };
      }
    }

    BlocProvider.of<CategoryBloc>(context).add(
      UpdateCategoryEvent(
        id: widget.category.id,
        name: _nameController.text,
        description: _descriptionController.text,
        isActive: _isActive,
        parentId: _selectedParentId,
        image: imageData,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animController.dispose();
    super.dispose();
  }
}