import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/salon_model.dart';
import '../models/user_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';

class SalonListScreen extends ConsumerStatefulWidget {
  const SalonListScreen({super.key});

  @override
  ConsumerState<SalonListScreen> createState() => _SalonListScreenState();
}

class _SalonListScreenState extends ConsumerState<SalonListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _profileImageBase64;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300, // Limit image size
      maxHeight: 300,
      imageQuality: 70, // Reduce quality to keep base64 string smaller
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _createSalon() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final salonId = _uuid.v4();
      final adminId = _uuid.v4();
      final now = DateTime.now();

      // Create salon admin user
      final adminData = {
        'id': adminId,
        'name': _nameController.text.trim(),
        'phoneNumber': Constants.formatPhoneNumber(_phoneController.text),
        'role': UserRole.salonAdmin.toString().split('.').last,
        'salonId': salonId,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Create salon
      final salonData =
          SalonModel(
            id: salonId,
            name: _nameController.text.trim(),
            phoneNumber: Constants.formatPhoneNumber(_phoneController.text),
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            description: _descriptionController.text.trim(),
            profileImageBase64: _profileImageBase64,
            adminId: adminId,
            createdAt: now,
            updatedAt: now,
          ).toJson();

      // Use a batch to ensure both documents are created
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection(Constants.usersCollection).doc(adminId),
        adminData,
      );
      batch.set(
        _firestore.collection(Constants.salonsCollection).doc(salonId),
        salonData,
      );
      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop(); // Close create salon dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salon created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating salon: $e')));
      }
    }
  }

  void _showCreateSalonDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Salon'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            _profileImageBase64 != null
                                ? MemoryImage(
                                  base64Decode(_profileImageBase64!),
                                )
                                : null,
                        child:
                            _profileImageBase64 == null
                                ? const Icon(Icons.add_a_photo, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: 'Salon Name',
                      controller: _nameController,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Enter salon name'
                                  : null,
                    ),
                    CustomTextField(
                      hintText: 'Phone Number (8 digits, we will add 973)',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter phone number';
                        }
                        final cleanNumber = value.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (cleanNumber.length != 8) {
                          return 'Phone number must be 8 digits';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      hintText: 'Address',
                      controller: _addressController,
                    ),
                    CustomTextField(
                      hintText: 'City',
                      controller: _cityController,
                    ),
                    CustomTextField(
                      hintText: 'Description',
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              CustomButton(text: 'Create', onPressed: _createSalon),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salons'),
        backgroundColor: AppColor.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(Constants.salonsCollection).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final salons = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: salons.length,
            itemBuilder: (context, index) {
              final salon = SalonModel.fromJson({
                'id': salons[index].id,
                ...salons[index].data() as Map<String, dynamic>,
              });

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        salon.profileImageBase64 != null
                            ? MemoryImage(
                              base64Decode(salon.profileImageBase64!),
                            )
                            : null,
                    child:
                        salon.profileImageBase64 == null
                            ? Text(salon.name[0].toUpperCase())
                            : null,
                  ),
                  title: Text(salon.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(salon.phoneNumber),
                      if (salon.address != null) Text(salon.address!),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to salon details page
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSalonDialog,
        backgroundColor: AppColor.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
