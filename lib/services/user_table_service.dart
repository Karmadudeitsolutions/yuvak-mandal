import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserTableService {
  static const String _usersTableKey = 'users_table';
  static const String _currentUserIdKey = 'current_user_id';

  // Simple result class for operations
  static Map<String, dynamic> createResult(bool success, String message, {User? user}) {
    return {
      'success': success,
      'message': message,
      'user': user,
    };
  }

  // Save all users to local storage (simulating users table)
  static Future<void> _saveUsersTable(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => user.toJson()).toList();
    await prefs.setString(_usersTableKey, jsonEncode(usersJson));
  }

  // Load all users from local storage (simulating users table)
  static Future<List<User>> _loadUsersTable() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersTableKey);
    if (usersJson != null) {
      final List<dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  // Set current logged-in user
  static Future<void> _setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
  }

  // Get current logged-in user ID
  static Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey);
  }

  // Clear current user (logout)
  static Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  // Create user - just insert into users table
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String phone,
    required String password, // We store it but don't use it for auth
    String role = 'Member',
  }) async {
    try {
      // Load existing users
      final users = await _loadUsersTable();
      
      // Check if email already exists
      final existingUser = users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => User(id: '', name: '', email: '', phone: ''),
      );
      
      if (existingUser.id.isNotEmpty) {
        return createResult(false, 'Email already exists in users table');
      }

      // Create new user
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final newUser = User(
        id: userId,
        name: name,
        email: email,
        phone: phone,
        role: role,
      );

      // Add to users table
      users.add(newUser);
      await _saveUsersTable(users);
      
      // Set as current user
      await _setCurrentUserId(userId);

      return createResult(true, 'User created successfully in users table', user: newUser);
    } catch (e) {
      return createResult(false, 'Failed to create user: ${e.toString()}');
    }
  }

  // Login user - just find in users table and set as current
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password, // We ignore password, just find by email
  }) async {
    try {
      // Load users table
      final users = await _loadUsersTable();
      
      // Find user by email
      final user = users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => User(id: '', name: '', email: '', phone: ''),
      );
      
      if (user.id.isEmpty) {
        return createResult(false, 'User not found in users table');
      }

      // Set as current user (no password check)
      await _setCurrentUserId(user.id);

      return createResult(true, 'User logged in from users table', user: user);
    } catch (e) {
      return createResult(false, 'Login failed: ${e.toString()}');
    }
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return null;

      final users = await _loadUsersTable();
      final user = users.firstWhere(
        (user) => user.id == currentUserId,
        orElse: () => User(id: '', name: '', email: '', phone: ''),
      );

      return user.id.isNotEmpty ? user : null;
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final currentUser = await getCurrentUser();
    return currentUser != null;
  }

  // Get all users from table
  static Future<List<User>> getAllUsers() async {
    return await _loadUsersTable();
  }

  // Update user in table
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? role,
  }) async {
    try {
      final users = await _loadUsersTable();
      final userIndex = users.indexWhere((user) => user.id == userId);
      
      if (userIndex == -1) {
        return createResult(false, 'User not found in users table');
      }

      final existingUser = users[userIndex];
      final updatedUser = User(
        id: existingUser.id,
        name: name ?? existingUser.name,
        email: existingUser.email,
        phone: phone ?? existingUser.phone,
        role: role ?? existingUser.role,
      );

      users[userIndex] = updatedUser;
      await _saveUsersTable(users);

      return createResult(true, 'User updated in users table', user: updatedUser);
    } catch (e) {
      return createResult(false, 'Failed to update user: ${e.toString()}');
    }
  }

  // Delete user from table
  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final users = await _loadUsersTable();
      final userIndex = users.indexWhere((user) => user.id == userId);
      
      if (userIndex == -1) {
        return createResult(false, 'User not found in users table');
      }

      users.removeAt(userIndex);
      await _saveUsersTable(users);

      // Clear current user if it was deleted
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == userId) {
        await clearCurrentUser();
      }

      return createResult(true, 'User deleted from users table');
    } catch (e) {
      return createResult(false, 'Failed to delete user: ${e.toString()}');
    }
  }

  // Get system info
  static Map<String, dynamic> getSystemInfo() {
    return {
      'authenticationService': false,
      'usersTable': true,
      'storageMethod': 'Local SharedPreferences',
      'authMethod': 'Direct Table Access',
      'emailVerification': false,
      'passwordAuth': false,
    };
  }
}