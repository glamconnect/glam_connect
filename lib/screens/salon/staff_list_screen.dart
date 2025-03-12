import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/staff_model.dart';
import 'package:glam_connect/providers/staff_provider.dart';
import 'package:glam_connect/utils/app_colors.dart';
import 'package:glam_connect/widgets/common/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  final String salonId;

  const StaffListScreen({super.key, required this.salonId});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  List<StaffModel> _staffList = [];
  late final TextEditingController _addNameController;
  late final TextEditingController _addPhoneController;
  late final TextEditingController _editNameController;
  late final TextEditingController _editPhoneController;

  @override
  void initState() {
    super.initState();
    _addNameController = TextEditingController();
    _addPhoneController = TextEditingController();
    _editNameController = TextEditingController();
    _editPhoneController = TextEditingController();
    _loadStaff();
  }

  @override
  void dispose() {
    _addNameController.dispose();
    _addPhoneController.dispose();
    _editNameController.dispose();
    _editPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    final staffList = await ref
        .read(staffProvider.notifier)
        .getStaffBySalonId(widget.salonId);
    setState(() {
      _staffList = staffList;
    });
  }

  Future<void> _showAddStaffDialog() async {
    _addNameController.clear();
    _addPhoneController.clear();
    String? profileImageBase64;
    bool isActive = true;

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
                    profileImageBase64 = base64Encode(bytes);
                  });
                }
              }

              return AlertDialog(
                title: const Text('Add New Staff'),
                content: SingleChildScrollView(
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
                              profileImageBase64 != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(profileImageBase64!),
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
                        hintText: 'Staff Name',
                        controller: _addNameController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hintText: 'Phone Number',
                        controller: _addPhoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: isActive,
                        onChanged:
                            (value) => setDialogState(() => isActive = value),
                      ),
                    ],
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
                      if (_addNameController.text.isEmpty ||
                          _addPhoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }

                      final staff = await ref
                          .read(staffProvider.notifier)
                          .createStaff(
                            salonId: widget.salonId,
                            name: _addNameController.text,
                            phoneNumber: _addPhoneController.text,
                            photoUrl: profileImageBase64,
                            isActive: isActive,
                          );

                      if (staff != null && mounted) {
                        Navigator.pop(context);
                        _loadStaff(); // Refresh the list
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to create staff. Phone number might be already registered.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _showEditStaffDialog(StaffModel staff) async {
    _editNameController.text = staff.name;
    _editPhoneController.text = staff.phoneNumber;
    String? profileImageBase64 = staff.photoUrl;
    bool isActive = staff.isActive;

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
                    profileImageBase64 = base64Encode(bytes);
                  });
                }
              }

              return AlertDialog(
                title: const Text('Edit Staff'),
                content: SingleChildScrollView(
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
                              profileImageBase64 != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(profileImageBase64!),
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
                        hintText: 'Staff Name',
                        controller: _addNameController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hintText: 'Phone Number',
                        controller: _addPhoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: isActive,
                        onChanged:
                            (value) => setDialogState(() => isActive = value),
                      ),
                    ],
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
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete Staff'),
                              content: const Text(
                                'Are you sure you want to delete this staff member?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (confirm == true) {
                        final success = await ref
                            .read(staffProvider.notifier)
                            .deleteStaff(staff.id);
                        if (success && mounted) {
                          Navigator.pop(context);
                          _loadStaff(); // Refresh the list
                        }
                      }
                    },
                    child: const Text('Delete'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (_editNameController.text.isEmpty ||
                          _editPhoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }

                      final success = await ref
                          .read(staffProvider.notifier)
                          .updateStaff(
                            id: staff.id,
                            name: _editNameController.text,
                            phoneNumber: _editPhoneController.text,
                            photoUrl: profileImageBase64,
                            isActive: isActive,
                          );

                      if (success && mounted) {
                        Navigator.pop(context);
                        _loadStaff(); // Refresh the list
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to update staff. Phone number might be already registered.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildStaffCard(StaffModel staff) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColor.primary.withOpacity(0.1),
          child:
              staff.photoUrl != null
                  ? ClipOval(
                    child: Image.memory(
                      base64Decode(staff.photoUrl!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                  : const Icon(Icons.person, color: AppColor.primary),
        ),
        title: Text(staff.name),
        subtitle: Text(staff.phoneNumber),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: staff.isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                staff.isActive ? 'Active' : 'Inactive',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditStaffDialog(staff),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStaffDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _staffList.length,
        itemBuilder: (context, index) => _buildStaffCard(_staffList[index]),
      ),
    );
  }
}
