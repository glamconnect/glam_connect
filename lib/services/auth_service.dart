import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/user_model.dart';
import 'package:glam_connect/utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection(Constants.usersCollection).doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromJson({
          'id': user.uid,
          ...userDoc.data()!,
        });
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Sign in with phone number (send OTP)
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String) onVerificationSent,
    required Function(String) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onVerificationSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verify OTP and sign in
  Future<User?> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error verifying OTP: $e');
      return null;
    }
  }

  // Register new user
  Future<UserModel?> registerUser({
    required String name,
    required String phoneNumber,
    String? email,
    String? city,
    UserRole role = UserRole.normalUser,
    String? salonId,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final userData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'city': city,
        'role': role.toString().split('.').last,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        if (salonId != null) 'salonId': salonId,
      };

      await _firestore.collection(Constants.usersCollection).doc(user.uid).set(userData);

      return UserModel(
        id: user.uid,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        city: city,
        role: role,
        createdAt: now,
        updatedAt: now,
        salonId: salonId,
      );
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _firestore
          .collection(Constants.usersCollection)
          .where('role', isEqualTo: role.toString().split('.').last)
          .get();

      return querySnapshot.docs.map((doc) {
        return UserModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // Get user by phone number
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection(Constants.usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return UserModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }
      return null;
    } catch (e) {
      print('Error getting user by phone: $e');
      return null;
    }
  }

  // Update user role
  Future<bool> updateUserRole({
    required String userId,
    required UserRole newRole,
    String? salonId,
  }) async {
    try {
      final updateData = {
        'role': newRole.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (salonId != null) {
        updateData['salonId'] = salonId;
      }

      await _firestore.collection(Constants.usersCollection).doc(userId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
