import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/service_category_model.dart';
import 'package:glam_connect/providers/service_category_provider.dart';
import 'package:glam_connect/utils/app_colors.dart';
import 'package:glam_connect/utils/image_utils.dart';
import 'package:glam_connect/widgets/common/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';

class ServiceCategoriesScreen extends ConsumerStatefulWidget {
  const ServiceCategoriesScreen({super.key});

  @override
  ConsumerState<ServiceCategoriesScreen> createState() =>
      _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState
    extends ConsumerState<ServiceCategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isActive = true;
  String? _selectedParentId;
  String? _profileImageBase64;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showAddCategoryDialog([ServiceCategory? category]) async {
    // Reset state before showing dialog
    _nameController.text = category?.name ?? '';
    _isActive = category?.isActive ?? true;
    _selectedParentId = category?.parentCategoryId;
    _selectedImage = null;
    _profileImageBase64 = null;

    final categories = ref.read(serviceCategoryProvider).value ?? [];
    final mainCategories =
        categories.where((c) => c.parentCategoryId == null).toList();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> pickImage() async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 300,
                  maxHeight: 300,
                  imageQuality: 85,
                );

                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setDialogState(() {
                    _selectedImage = File(image.path);
                    _profileImageBase64 = base64Encode(bytes);
                  });
                }
              }

              return AlertDialog(
                title: Text(
                  category == null ? 'Add Category' : 'Edit Category',
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                _profileImageBase64 != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        base64Decode(_profileImageBase64!),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : (category?.base64Image ?? '').isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        base64Decode(category!.base64Image!),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.add_photo_alternate,
                                      color: AppColor.primary,
                                      size: 40,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: 'Category Name',
                          controller: _nameController,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? 'Please enter a name'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String?>(
                          value: _selectedParentId,
                          decoration: const InputDecoration(
                            labelText: 'Parent Category (Optional)',
                            floatingLabelStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColor.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('None (Main Category)'),
                            ),
                            ...mainCategories.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged:
                              (value) => setDialogState(
                                () => _selectedParentId = value,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Active'),
                          value: _isActive,
                          onChanged:
                              (value) =>
                                  setDialogState(() => _isActive = value),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColor.primary),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        if (category == null) {
                          // Create new category
                          final result = await ref
                              .read(serviceCategoryProvider.notifier)
                              .createCategory(
                                name: _nameController.text,
                                isActive: _isActive,
                                imageFile: _selectedImage,
                                parentCategoryId: _selectedParentId,
                                createdBy:
                                    'superadmin', // TODO: Get actual user ID
                              );
                          if (result != null && mounted) {
                            Navigator.pop(context);
                          }
                        } else {
                          // Update existing category
                          final success = await ref
                              .read(serviceCategoryProvider.notifier)
                              .updateCategory(
                                id: category.id,
                                name: _nameController.text,
                                isActive: _isActive,
                                newImageFile: _selectedImage,
                                parentCategoryId: _selectedParentId,
                              );
                          if (success && mounted) {
                            Navigator.pop(context);
                          }
                        }
                      }
                    },
                    child: Text(category == null ? 'Create' : 'Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    final isSubCategory = category.parentCategoryId != null;

    return Card(
      margin: EdgeInsets.only(left: isSubCategory ? 32 : 0, bottom: 8),
      child: ListTile(
        leading:
            category.base64Image != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: ImageUtils.getImageProvider(category.base64Image),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                : Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.category),
                ),
        title: Text(category.name),
        subtitle: Text(category.isActive ? 'Active' : 'Inactive'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddCategoryDialog(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Category'),
                        content: const Text(
                          'Are you sure you want to delete this category?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  await ref
                      .read(serviceCategoryProvider.notifier)
                      .deleteCategory(category.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(serviceCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service Categories',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),

      body: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (categories) {
          final mainCategories =
              categories.where((c) => c.parentCategoryId == null).toList();
          final subCategories =
              categories.where((c) => c.parentCategoryId != null).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(serviceCategoryProvider.notifier).loadCategories();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...mainCategories.map((category) {
                  final children =
                      subCategories
                          .where((sub) => sub.parentCategoryId == category.id)
                          .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryCard(category),
                      ...children.map(_buildCategoryCard),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
