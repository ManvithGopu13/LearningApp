import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Local storage service for persisting user data
class StorageService {
  static const String _userKey = 'current_user';
  static const String _userIdKey = 'user_id';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the storage service
  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  /// Save user to local storage
  Future<bool> saveUser(User user) async {
    await init();
    try {
      final userJson = json.encode(user.toJson());
      await _prefs.setString(_userKey, userJson);
      await _prefs.setString(_userIdKey, user.userId);
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  /// Get current user from local storage
  Future<User?> getUser() async {
    await init();
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson == null) return null;
      
      final userMap = json.decode(userJson);
      return User.fromJson(userMap);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Get user ID from local storage
  Future<String?> getUserId() async {
    await init();
    return _prefs.getString(_userIdKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    await init();
    return _prefs.containsKey(_userKey);
  }

  /// Clear user data (logout)
  Future<bool> clearUser() async {
    await init();
    try {
      await _prefs.remove(_userKey);
      await _prefs.remove(_userIdKey);
      return true;
    } catch (e) {
      print('Error clearing user: $e');
      return false;
    }
  }

  /// Clear all data
  Future<bool> clearAll() async {
    await init();
    try {
      await _prefs.clear();
      return true;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }
}