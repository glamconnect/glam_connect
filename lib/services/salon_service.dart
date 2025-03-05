import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/salon_model.dart';
import 'package:glam_connect/models/user_model.dart';
import 'package:glam_connect/services/auth_service.dart';
import 'package:glam_connect/utils/constants.dart';
import 'package:uuid/uuid.dart';

final salonServiceProvider = Provider<SalonService>((ref) {
  return SalonService(ref);
});

class SalonService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  SalonService(this._ref);

  // Get all salons
  Future<List<SalonModel>> getAllSalons() async {
    try {
      final querySnapshot = await _firestore.collection(Constants.salonsCollection).get();
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return SalonModel.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      print('Error getting salons: $e');
      return [];
    }
  }

  // Get salon by ID
  Future<SalonModel?> getSalonById(String salonId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(Constants.salonsCollection)
          .doc(salonId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return SalonModel.fromJson({
            'id': doc.id,
            ...(data as Map<String, dynamic>),
          });
        }
      }
      return null;
    } catch (e) {
      print('Error getting salon: $e');
      return null;
    }
  }

  // Create a new salon
  Future<SalonModel?> createSalon({
    required String name,
    required String phoneNumber,
    String? profileImageBase64,
  }) async {
    try {
      final String salonId = const Uuid().v4();
      final DateTime now = DateTime.now();

      // Create salon document
      final salonData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'profileImageBase64': profileImageBase64,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await _firestore.collection(Constants.salonsCollection).doc(salonId).set(salonData);

      // Create salon admin user
      final existingUser = await _authService.getUserByPhone(phoneNumber);
      String adminId;

      if (existingUser != null) {
        // Update existing user to salon admin role
        await _authService.updateUserRole(
          userId: existingUser.id,
          newRole: UserRole.salonAdmin,
          salonId: salonId,
        );
        adminId = existingUser.id;
      } else {
        // Create new user with salon admin role
        final newUser = await _authService.registerUser(
          name: 'Admin for $name',
          phoneNumber: phoneNumber,
          role: UserRole.salonAdmin,
          salonId: salonId,
        );
        adminId = newUser?.id ?? '';
      }

      // Update salon with admin ID
      await _firestore.collection(Constants.salonsCollection).doc(salonId).update({'adminId': adminId});

      return SalonModel(
        id: salonId,
        name: name,
        phoneNumber: phoneNumber,
        profileImageBase64: profileImageBase64,
        adminId: adminId,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      print('Error creating salon: $e');
      return null;
    }
  }

  // Update salon details
  Future<SalonModel?> updateSalon({
    required String salonId,
    String? name,
    String? phoneNumber,
    String? address,
    String? city,
    String? description,
    String? profileImageBase64,
  }) async {
    try {
      final salonDoc = await _firestore.collection(Constants.salonsCollection).doc(salonId).get();
      if (!salonDoc.exists) return null;

      final updatedData = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updatedData['name'] = name;
      if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;
      if (address != null) updatedData['address'] = address;
      if (city != null) updatedData['city'] = city;
      if (description != null) updatedData['description'] = description;
      if (profileImageBase64 != null) {
        updatedData['profileImageBase64'] = profileImageBase64;
      }

      await _firestore.collection(Constants.salonsCollection).doc(salonId).update(updatedData);

      // Get updated salon data
      final updatedSalonDoc = await _firestore.collection(Constants.salonsCollection).doc(salonId).get();
      final updatedSalonData = updatedSalonDoc.data();
      if (updatedSalonData != null) {
        return SalonModel.fromJson({
          'id': salonId,
          ...(updatedSalonData as Map<String, dynamic>),
        });
      }
      return null;
    } catch (e) {
      print('Error updating salon: $e');
      return null;
    }
  }

  // Delete a salon
  Future<bool> deleteSalon(String salonId) async {
    try {
      await _firestore.collection(Constants.salonsCollection).doc(salonId).delete();
      return true;
    } catch (e) {
      print('Error deleting salon: $e');
      return false;
    }
  }
}
