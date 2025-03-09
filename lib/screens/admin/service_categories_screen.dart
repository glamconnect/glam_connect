import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/service_category_model.dart';
import 'package:glam_connect/providers/service_category_provider.dart';
import 'package:glam_connect/utils/app_colors.dart';
import 'package:glam_connect/utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';

class ServiceCategoriesScreen extends ConsumerStatefulWidget {
  const ServiceCategoriesScreen({super.key});

  @override
  ConsumerState<ServiceCategoriesScreen> createState() => _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState extends ConsumerState<ServiceCategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isActive = true;
  String? _selectedParentId;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _showAddCategoryDialog([ServiceCategory? category]) async {
    _nameController.text = category?.name ?? '';
    _isActive = category?.isActive ?? true;
    _selectedParentId = category?.parentCategoryId;
    _selectedImage = null;

    final categories = ref.read(serviceCategoryProvider).value ?? [];
    final mainCategories = categories.where((c) => c.parentCategoryId == null).toList();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : category?.base64Image != null
                              ? DecorationImage(
                                  image: ImageUtils.getImageProvider(category!.base64Image),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _selectedImage == null && category?.base64Image == null
                        ? const Icon(Icons.add_photo_alternate, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedParentId,
                  decoration: const InputDecoration(
                    labelText: 'Parent Category (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None (Main Category)'),
                    ),
                    ...mainCategories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedParentId = value),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                if (category == null) {
                  // Create new category
                  final result = await ref.read(serviceCategoryProvider.notifier).createCategory(
                        name: _nameController.text,
                        isActive: _isActive,
                        imageFile: _selectedImage,
                        parentCategoryId: _selectedParentId,
                        createdBy: 'superadmin', // TODO: Get actual user ID
                      );
                  if (result != null && mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  // Update existing category
                  final success = await ref.read(serviceCategoryProvider.notifier).updateCategory(
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
      ),
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    final isSubCategory = category.parentCategoryId != null;
    
    return Card(
      margin: EdgeInsets.only(
        left: isSubCategory ? 32 : 0,
        bottom: 8,
      ),
      child: ListTile(
        leading: category.base64Image != null
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
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Category'),
                    content: const Text('Are you sure you want to delete this category?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(serviceCategoryProvider.notifier).deleteCategory(category.id);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppColor.primary,
        child: const Icon(Icons.add),
      ),
      body: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (categories) {
          final mainCategories = categories.where((c) => c.parentCategoryId == null).toList();
          final subCategories = categories.where((c) => c.parentCategoryId != null).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(serviceCategoryProvider.notifier).loadCategories();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...mainCategories.map((category) {
                  final children = subCategories
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
