import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/user_model.dart';
import 'package:glam_connect/services/shared_preferences_service.dart';
import 'package:glam_connect/utils/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final SharedPreferencesService _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  AuthService(this._prefs);

  // Get current user from local storage
  Future<UserModel?> getCurrentUser() async {
    return _prefs.getUserData();
  }

  // Check if phone number exists and send dummy OTP
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String) onVerificationSent,
    required Function(String) onError,
  }) async {
    try {
      // Clean and format phone number
      final formattedPhone = Constants.formatPhoneNumber(phoneNumber);
      print('Attempting to sign in with phone number: $formattedPhone');

      // Check if user exists
      final user = await getUserByPhone(formattedPhone);
      if (user == null) {
        onError('Phone number not registered');
        return;
      }

      // Generate a dummy verification ID
      final verificationId = _uuid.v4();
      onVerificationSent(verificationId);
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verify OTP (simplified to just check for 0000)
  Future<(UserModel?, String?)> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      // Only accept 0000 as valid OTP
      if (otp != '0000') {
        return (null, 'Invalid OTP');
      }

      // Get user data from local storage
      final user = await getCurrentUser();
      if (user != null) {
        return (user, null);
      }
      return (null, 'User data not found');
    } catch (e) {
      print('Error verifying OTP: $e');
      return (null, 'OTP verification failed: $e');
    }
  }

  // Register new user
  Future<(UserModel?, String?)> registerUser({
    required String name,
    required String phoneNumber,
    String? email,
    String? city,
    UserRole role = UserRole.customer,
    String? salonId,
  }) async {
    try {
      // Clean and format phone number
      final formattedPhone = Constants.formatPhoneNumber(phoneNumber);

      // Check if phone number already exists
      final existingUser = await getUserByPhone(formattedPhone);
      if (existingUser != null) {
        return (null, 'Phone number already registered');
      }

      final now = DateTime.now();
      final userId = _uuid.v4(); // Generate unique ID
      final userData = {
        'id': userId,
        'name': name,
        'phoneNumber': formattedPhone,
        'email': email,
        'city': city,
        'role': role.toString().split('.').last,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        if (salonId != null) 'salonId': salonId,
      };

      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        userData['fcmToken'] = fcmToken;
      }

      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .set(userData);

      final newUser = UserModel(
        id: userId,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        city: city,
        role: role,
        createdAt: now,
        updatedAt: now,
        salonId: salonId,
        fcmToken: userData['fcmToken'],
      );

      // Store user data locally
      await _prefs.setUserData(newUser);

      return (newUser, null);
    } catch (e) {
      print('Error registering user: $e');
      return (null, 'Registration failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    final user = await getCurrentUser();
    if (user != null) {
      // Remove FCM token on sign out
      await _firestore
          .collection(Constants.usersCollection)
          .doc(user.id)
          .update({'fcmToken': null});
    }
    await _prefs.clearAll();
  }

  // Get user by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(Constants.usersCollection)
              .where('role', isEqualTo: role.toString().split('.').last)
              .get();

      return querySnapshot.docs.map((doc) {
        return UserModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // Login with phone number
  Future<(UserModel?, String?)> login(String phoneNumber) async {
    try {
      // Clean and format phone number
      final formattedPhone = Constants.formatPhoneNumber(phoneNumber);
      print('Attempting to login with phone number: "$formattedPhone"');

      final querySnapshot =
          await _firestore
              .collection(Constants.usersCollection)
              .where('phoneNumber', isEqualTo: formattedPhone)
              .get();

      print('Query found ${querySnapshot.docs.length} documents');
      if (querySnapshot.docs.isEmpty) {
        print('No user found with phone number: "$formattedPhone"');
        return (null, 'Phone number not registered');
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      print('Found user document: ${doc.id}');
      print('Document data: $data');

      // Create user model with formatted phone number
      data['phoneNumber'] = formattedPhone;
      final user = UserModel.fromJson({'id': doc.id, ...data});

      // Update FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      UserModel userToStore = user;

      if (fcmToken != null) {
        await _firestore
            .collection(Constants.usersCollection)
            .doc(user.id)
            .update({'fcmToken': fcmToken});

        // Create new user instance with updated FCM token
        userToStore = UserModel(
          id: user.id,
          name: user.name,
          phoneNumber: user.phoneNumber,
          email: user.email,
          city: user.city,
          role: user.role,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          salonId: user.salonId,
          fcmToken: fcmToken,
        );
      }

      // Store user data locally
      await _prefs.setUserData(userToStore);
      return (userToStore, null);
    } catch (e) {
      print('Error logging in: $e');
      return (null, 'Login failed: $e');
    }
  }

  // Get user by phone number
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      // Clean and format phone number
      final phoneStr = Constants.formatPhoneNumber(phoneNumber);
      print('Querying for phone number: "$phoneStr"');

      // List all users to debug
      final allUsers =
          await _firestore.collection(Constants.usersCollection).get();

      print('All users in database:');
      for (var doc in allUsers.docs) {
        final dbPhone = Constants.formatPhoneNumber(doc.data()['phoneNumber']);
        print(
          'User ${doc.id}: phoneNumber = "$dbPhone" (original = "${doc.data()['phoneNumber']}"), type = ${doc.data()['phoneNumber'].runtimeType}',
        );
      }

      // Check users collection first
      var querySnapshot =
          await _firestore
              .collection(Constants.usersCollection)
              .where('phoneNumber', isEqualTo: phoneStr)
              .limit(1)
              .get();

      // If not found in users, check staff collection
      if (querySnapshot.docs.length == 0) {
        querySnapshot =
            await _firestore
                .collection(Constants.staffCollection)
                .where('phoneNumber', isEqualTo: phoneStr)
                .limit(1)
                .get();
      }



      print('Query result: ${querySnapshot.docs.length} documents found');

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        // Ensure phone number is properly formatted
        data['phoneNumber'] = Constants.formatPhoneNumber(data['phoneNumber']);
        return UserModel.fromJson({'id': doc.id, ...data});
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

      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }
}

final authServiceFutureProvider = FutureProvider<AuthService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesServiceFutureProvider.future);
  return AuthService(prefs);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final authService = ref.watch(authServiceFutureProvider);
  return authService.when(
    data: (service) => service,
    loading:
        () => throw UnimplementedError('AuthService is still initializing'),
    error: (error, _) => throw error,
  );
});
