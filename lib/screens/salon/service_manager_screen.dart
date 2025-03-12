import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/service_model.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/providers/service_category_provider.dart';
import 'package:glam_connect/providers/service_provider.dart';
import 'package:glam_connect/widgets/common/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glam_connect/utils/image_utils.dart';

import '../../utils/app_colors.dart';

class ServiceManagerScreen extends ConsumerStatefulWidget {
  const ServiceManagerScreen({super.key});

  @override
  ConsumerState<ServiceManagerScreen> createState() =>
      _ServiceManagerScreenState();
}

class _ServiceManagerScreenState extends ConsumerState<ServiceManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategoryId;
  bool _isActive = true;
  String? _profileImageBase64;
  ServiceModel? _service;

  @override
  void initState() {
    super.initState();
    // Load categories and services
    Future.microtask(() {
      ref.read(serviceCategoryProvider.notifier).loadCategories();
      final currentUser = ref.read(mainProvider).currentUser;
      if (currentUser?.salonId != null) {
        ref
            .read(serviceProvider.notifier)
            .getServicesBySalonId(currentUser!.salonId!);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBase64 = base64Encode(imageBytes);
      });
    }
  }

  Future<void> _showAddServiceDialog([ServiceModel? service]) async {
    _resetForm();
    _nameController.text = service?.name ?? '';
    _descriptionController.text = service?.description ?? '';
    _priceController.text = service?.price.toString() ?? '';
    _selectedCategoryId = service?.categoryId;
    setState(() {
      _service = service;
      _profileImageBase64 = null;
    });
    _isActive = service?.isActive ?? true;
    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> pickImage() async {
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );

                if (pickedFile != null) {
                  final imageBytes = await pickedFile.readAsBytes();
                  setDialogState(() {
                    _profileImageBase64 = base64Encode(imageBytes);
                  });
                }
              }

              final categories = ref.watch(serviceCategoryProvider).value ?? [];

              return AlertDialog(
                title: const Text('Add New Service'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.1),
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
                                    : (_service?.base64Image ?? '').isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        base64Decode(_service!.base64Image!),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Icon(
                                      Icons.add_photo_alternate,
                                      color: AppColor.primary,
                                      size: 40,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _nameController,
                          hintText: 'Service Name',
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? 'Please enter a name'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _descriptionController,
                          hintText: 'Description',
                          maxLines: 3,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? 'Please enter a description'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _priceController,
                          hintText: 'Price',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Please enter a price';
                            if (double.tryParse(value!) == null) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              categories.map((category) {
                                return DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select a category'
                                      : null,
                        ),
                        const SizedBox(height: 16),

                        SwitchListTile(
                          title: const Text('Active'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
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
                  TextButton(
                    onPressed: _handleAddService,
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _selectedCategoryId = null;
    _isActive = true;
    _profileImageBase64 = null;
    _service = null;
  }

  Future<void> _handleAddService() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(mainProvider).currentUser;
    if (currentUser == null || currentUser.salonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Salon ID not found')),
      );
      return;
    }

    final success = await ref
        .read(serviceProvider.notifier)
        .createService(
          name: _nameController.text,
          description: _descriptionController.text,
          price: _priceController.text,
          isActive: _isActive,
          salonId: currentUser.salonId!,
          categoryId: _selectedCategoryId!,
          base64Image: _profileImageBase64,
          createdBy: currentUser.id,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Service added successfully' : 'Failed to add service',
          ),
        ),
      );
    }
  }

  Future<void> _handleEditService(String serviceId) async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(mainProvider).currentUser;
    if (currentUser == null || currentUser.salonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Salon ID not found')),
      );
      return;
    }

    final success = await ref
        .read(serviceProvider.notifier)
        .updateService(
          id: serviceId,
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          isActive: _isActive,
          salonId: currentUser.salonId!,
          categoryId: _selectedCategoryId!,
          base64Image: _profileImageBase64,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Service updated successfully'
                : 'Failed to update service',
          ),
        ),
      );
    }
  }

  Future<void> _handleDeleteService(String serviceId) async {
    final currentUser = ref.read(mainProvider).currentUser;
    if (currentUser?.salonId == null) return;

    final success = await ref
        .read(serviceProvider.notifier)
        .deleteService(serviceId, currentUser!.salonId!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Service deleted successfully'
                : 'Failed to delete service',
          ),
        ),
      );
    }
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading:
        service.base64Image != null
            ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image(
                image: ImageUtils.getImageProvider(service.base64Image),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
        :
        const Icon(Icons.spa),
        title: Text(service.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.description),
            Text('Price: \$${service.price.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: service.isActive,
              onChanged: (value) => _handleEditService(service.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddServiceDialog(service),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _handleDeleteService(service.id),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(mainProvider).currentUser;
    final services = ref.watch(serviceProvider);

    if (currentUser?.salonId == null) {
      return const Center(child: Text('Error: Salon ID not found'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Manager'),
        backgroundColor: AppColor.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddServiceDialog,
          ),
        ],
      ),
      body: services.when(
        data: (services) {
          if (services.isEmpty) {
            return const Center(
              child: Text('No services added yet. Click + to add a service.'),
            );
          }
          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) => _buildServiceCard(services[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(child: Text('Error: ${error.toString()}')),
      ),
    );
  }
}
