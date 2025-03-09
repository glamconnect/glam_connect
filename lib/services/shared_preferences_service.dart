import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glam_connect/utils/constants.dart';
import 'package:glam_connect/models/user_model.dart';

class SharedPreferencesService {
  late final SharedPreferences _prefs;
  
  SharedPreferencesService._();
  
  static Future<SharedPreferencesService> create() async {
    final service = SharedPreferencesService._();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }
  
  // User ID
  Future<void> setUserId(String userId) async {
    await _prefs.setString(Constants.userIdKey, userId);
  }
  
  String? getUserId() {
    return _prefs.getString(Constants.userIdKey);
  }
  
  // User Role
  Future<void> setUserRole(String role) async {
    await _prefs.setString(Constants.userRoleKey, role);
  }
  
  String? getUserRole() {
    return _prefs.getString(Constants.userRoleKey);
  }
  
  // Store complete user data
  Future<void> setUserData(UserModel user) async {
    await _prefs.setString(Constants.userIdKey, user.id);
    await _prefs.setString(Constants.userRoleKey, user.role.toString().split('.').last);
    await _prefs.setString('userData', jsonEncode(user.toJson()));
  }

  // Get complete user data
  UserModel? getUserData() {
    final userDataString = _prefs.getString('userData');
    if (userDataString == null) return null;
    
    try {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  // Clear all data (for logout)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

// Initialize SharedPreferences as a singleton
final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>((ref) {
  throw UnimplementedError('Use sharedPreferencesServiceFutureProvider instead');
});

final sharedPreferencesServiceFutureProvider = FutureProvider<SharedPreferencesService>((ref) async {
  return SharedPreferencesService.create();
});
