import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/staff_model.dart';

final staffProvider =
    AsyncNotifierProvider<StaffNotifier, List<StaffModel>>(StaffNotifier.new);

class StaffNotifier extends AsyncNotifier<List<StaffModel>> {
  final _staffCollection = FirebaseFirestore.instance.collection('staff');

  @override
  Future<List<StaffModel>> build() async {
    return [];
  }

  Future<List<StaffModel>> getStaffBySalonId(String salonId) async {
    // Temporarily removed orderBy until index is created
    final snapshot = await _staffCollection
        .where('salonId', isEqualTo: salonId)
        .get();

    return snapshot.docs
        .map((doc) => StaffModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<StaffModel?> createStaff({
    required String name,
    required String phoneNumber,
    required String salonId,
    String? photoUrl,
    bool isActive = true,
  }) async {
    try {
      // Check if phone number is already registered
      final existingStaff = await _staffCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();
      
      if (existingStaff.docs.isNotEmpty) {
        throw Exception('Phone number is already registered');
      }

      final docRef = await _staffCollection.add({
        'name': name,
        'phoneNumber': phoneNumber,
        'salonId': salonId,
        'photoUrl': photoUrl,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      return StaffModel.fromJson({'id': doc.id, ...doc.data()!});
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateStaff({
    required String id,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;
      if (isActive != null) updateData['isActive'] = isActive;

      if (phoneNumber != null) {
        // Check if phone number is already registered to another staff
        final existingStaff = await _staffCollection
            .where('phoneNumber', isEqualTo: phoneNumber)
            .where(FieldPath.documentId, isNotEqualTo: id)
            .get();
        
        if (existingStaff.docs.isNotEmpty) {
          throw Exception('Phone number is already registered');
        }
      }

      await _staffCollection.doc(id).update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteStaff(String id) async {
    try {
      await _staffCollection.doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<StaffModel?> getStaffByPhoneNumber(String phoneNumber) async {
    try {
      final snapshot = await _staffCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return StaffModel.fromJson({'id': doc.id, ...doc.data()});
    } catch (e) {
      return null;
    }
  }
}
