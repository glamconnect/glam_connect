import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glam_connect/utils/constants.dart';

class SharedPreferencesService {
  late SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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
  
  // Clear all data (for logout)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>((ref) {
  final service = SharedPreferencesService();
  service.init();
  return service;
});
