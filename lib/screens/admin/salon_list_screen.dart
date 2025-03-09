import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glam_connect/models/salon_model.dart';
import 'package:glam_connect/services/salon_service.dart';
import 'package:glam_connect/utils/app_theme.dart';
import 'package:glam_connect/widgets/common/custom_button.dart';
import 'package:glam_connect/widgets/common/custom_text_field.dart';

class SalonListScreen extends ConsumerStatefulWidget {
  const SalonListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SalonListScreen> createState() => _SalonListScreenState();
}

class _SalonListScreenState extends ConsumerState<SalonListScreen> {
  List<SalonModel> _salons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalons();
  }

  Future<void> _loadSalons() async {
    setState(() {
      _isLoading = true;
    });

    final salons = await ref.read(salonServiceProvider).getAllSalons();

    setState(() {
      _salons = salons;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Salons Manager',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddSalonDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              )
              : _buildSalonList(),
    );
  }

  Widget _buildSalonList() {
    if (_salons.isEmpty) {
      return const Center(
        child: Text(
          'No salons found. Add your first salon!',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salons.length,
      itemBuilder: (context, index) {
        final salon = _salons[index];
        return _buildSalonCard(salon);
      },
    );
  }

  Widget _buildSalonCard(SalonModel salon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppColor.primary.withOpacity(0.2),
          child:
              salon.profileImageBase64 != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.memory(
                      _decodeBase64Image(salon.profileImageBase64!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                  : Icon(Icons.store, color: AppColor.primary, size: 30),
        ),
        title: Text(
          salon.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Phone: ${salon.phoneNumber}'),
            if (salon.city != null) Text('City: ${salon.city}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColor.primary),
          onPressed: () => _showEditSalonDialog(salon),
        ),
        onTap: () {
          // Navigate to salon details page
          // Navigator.of(context).pushNamed('/salon-details', arguments: salon);
        },
      ),
    );
  }

  void _showAddSalonDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _CreateSalonDialog(
            onSalonCreated: (salon) {
              setState(() {
                _salons.add(salon);
              });
            },
          ),
    );
  }

  void _showEditSalonDialog(SalonModel salon) {
    showDialog(
      context: context,
      builder:
          (context) => _EditSalonDialog(
            salon: salon,
            onSalonUpdated: (updatedSalon) {
              setState(() {
                final index = _salons.indexWhere(
                  (s) => s.id == updatedSalon.id,
                );
                if (index != -1) {
                  _salons[index] = updatedSalon;
                }
              });
            },
          ),
    );
  }

  Uint8List _decodeBase64Image(String base64String) {
    return base64Decode(base64String);
  }
}

class _CreateSalonDialog extends ConsumerStatefulWidget {
  final Function(SalonModel) onSalonCreated;

  const _CreateSalonDialog({required this.onSalonCreated});

  @override
  ConsumerState<_CreateSalonDialog> createState() => _CreateSalonDialogState();
}

class _CreateSalonDialogState extends ConsumerState<_CreateSalonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  String? _profileImageBase64;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _createSalon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the salon with admin details
      final salon = await ref
          .read(salonServiceProvider)
          .createSalon(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            adminName: _adminNameController.text.trim(),
            adminEmail: _adminEmailController.text.trim(),
            profileImageBase64: _profileImageBase64,
          );

      if (salon == null) {
        throw Exception('Failed to create salon');
      }

      if (mounted) {
        widget.onSalonCreated(salon);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                  backgroundColor: AppColor.primary.withOpacity(0.1),
                  child:
                      _profileImageBase64 != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.memory(
                              base64Decode(_profileImageBase64!),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Icon(
                            Icons.add_a_photo,
                            color: AppColor.primary,
                            size: 40,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Salon Name',
                controller: _nameController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Enter salon name' : null,
              ),
              CustomTextField(
                hintText: 'Phone Number (8 digits, we will add 973)',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter phone number';
                  }
                  final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanNumber.length != 8) {
                    return 'Phone number must be 8 digits';
                  }
                  return null;
                },
              ),
              CustomTextField(
                hintText: 'Admin Name',
                controller: _adminNameController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Enter admin name' : null,
              ),
              CustomTextField(
                hintText: 'Admin Email',
                controller: _adminEmailController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Enter admin email' : null,
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
        CustomButton(
          text: 'Create',
          onPressed: _createSalon,
          isLoading: _isLoading,
          width: 100,
          height: 40,
        ),
      ],
    );
  }
}

class _EditSalonDialog extends ConsumerStatefulWidget {
  final SalonModel salon;
  final Function(SalonModel) onSalonUpdated;

  const _EditSalonDialog({required this.salon, required this.onSalonUpdated});

  @override
  ConsumerState<_EditSalonDialog> createState() => _EditSalonDialogState();
}

class _EditSalonDialogState extends ConsumerState<_EditSalonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  String? _profileImageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.salon.name;
    _phoneController.text = widget.salon.phoneNumber;
    _profileImageBase64 = widget.salon.profileImageBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _updateSalon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final salon = await ref
        .read(salonServiceProvider)
        .updateSalon(
          salonId: widget.salon.id,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          profileImageBase64: _profileImageBase64,
        );

    setState(() {
      _isLoading = false;
    });

    if (salon != null && mounted) {
      widget.onSalonUpdated(salon);
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update salon. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Salon'),
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
                  backgroundColor: AppColor.primary.withOpacity(0.1),
                  child:
                      _profileImageBase64 != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.memory(
                              base64Decode(_profileImageBase64!),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Icon(
                            Icons.add_a_photo,
                            color: AppColor.primary,
                            size: 40,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Salon Name',
                controller: _nameController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Enter salon name' : null,
              ),
              CustomTextField(
                hintText: 'Phone Number (8 digits, we will add 973)',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter phone number';
                  }
                  final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanNumber.length != 8) {
                    return 'Phone number must be 8 digits';
                  }
                  return null;
                },
              ),
              CustomTextField(
                hintText: 'Admin Name',
                controller: _adminNameController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Enter admin name' : null,
              ),
              CustomTextField(
                hintText: 'Admin Email',
                controller: _adminEmailController,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Enter admin email' : null,
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
        CustomButton(
          text: 'Update',
          onPressed: _updateSalon,
          isLoading: _isLoading,
          width: 100,
          height: 40,
        ),
      ],
    );
  }
}
