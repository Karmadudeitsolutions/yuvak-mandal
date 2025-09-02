import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Authentication Status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get Current User
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Register new user
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'Member',
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        return AuthResult(
          success: false,
          message: 'User with this email already exists',
        );
      }

      // Create new user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
        role: role,
      );

      // Save user credentials
      await _saveUserCredentials(email, password);
      
      // Save user to registered users list
      await _addUserToRegisteredList(user);

      // Set as current user
      await _setCurrentUser(user);

      return AuthResult(
        success: true,
        message: 'Account created successfully',
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // Login user
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validate credentials
      final isValidCredentials = await _validateCredentials(email, password);
      if (!isValidCredentials) {
        return AuthResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Get user data
      final user = await _getUserByEmail(email);
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'User not found',
        );
      }

      // Set as current user
      await _setCurrentUser(user);

      return AuthResult(
        success: true,
        message: 'Login successful',
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Update user profile
  static Future<AuthResult> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      // Create updated user
      final updatedUser = User(
        id: currentUser.id,
        name: name,
        email: currentUser.email,
        phone: phone,
        role: currentUser.role,
      );

      // Update in registered users list
      await _updateUserInRegisteredList(updatedUser);
      
      // Update current user
      await _setCurrentUser(updatedUser);

      return AuthResult(
        success: true,
        message: 'Profile updated successfully',
        user: updatedUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Profile update failed: ${e.toString()}',
      );
    }
  }

  // Change password
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      // Validate current password
      final isValidPassword = await _validateCredentials(
        currentUser.email,
        currentPassword,
      );
      
      if (!isValidPassword) {
        return AuthResult(
          success: false,
          message: 'Current password is incorrect',
        );
      }

      // Update password
      await _saveUserCredentials(currentUser.email, newPassword);

      return AuthResult(
        success: true,
        message: 'Password changed successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Password change failed: ${e.toString()}',
      );
    }
  }

  // Delete account
  static Future<AuthResult> deleteAccount({
    required String password,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      // Validate password
      final isValidPassword = await _validateCredentials(
        currentUser.email,
        password,
      );
      
      if (!isValidPassword) {
        return AuthResult(
          success: false,
          message: 'Password is incorrect',
        );
      }

      // Remove user from registered list
      await _removeUserFromRegisteredList(currentUser.email);
      
      // Remove credentials
      await _removeUserCredentials(currentUser.email);
      
      // Logout
      await logout();

      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Account deletion failed: ${e.toString()}',
      );
    }
  }

  // Get all registered users (for admin)
  static Future<List<User>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final List<dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((u) => User.fromJson(u)).toList();
    }
    return [];
  }

  // Reset password (mock implementation)
  static Future<AuthResult> resetPassword({
    required String email,
  }) async {
    try {
      final user = await _getUserByEmail(email);
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'No account found with this email',
        );
      }

      // In a real app, this would send an email
      // For now, we'll just generate a temporary password
      final tempPassword = 'temp${DateTime.now().millisecondsSinceEpoch}';
      await _saveUserCredentials(email, tempPassword);

      return AuthResult(
        success: true,
        message: 'Password reset successful. Temporary password: $tempPassword',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Password reset failed: ${e.toString()}',
      );
    }
  }

  // Private helper methods
  static Future<void> _setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  static Future<User?> _getUserByEmail(String email) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere((user) => user.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  static Future<void> _addUserToRegisteredList(User user) async {
    final users = await getAllUsers();
    users.add(user);
    await _saveAllUsers(users);
  }

  static Future<void> _updateUserInRegisteredList(User updatedUser) async {
    final users = await getAllUsers();
    final index = users.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      await _saveAllUsers(users);
    }
  }

  static Future<void> _removeUserFromRegisteredList(String email) async {
    final users = await getAllUsers();
    users.removeWhere((user) => user.email.toLowerCase() == email.toLowerCase());
    await _saveAllUsers(users);
  }

  static Future<void> _saveAllUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((u) => u.toJson()).toList();
    await prefs.setString(_usersKey, jsonEncode(usersJson));
  }

  static Future<void> _saveUserCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    // In a real app, password should be hashed
    await prefs.setString('password_${email.toLowerCase()}', password);
  }

  static Future<bool> _validateCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('password_${email.toLowerCase()}');
    return storedPassword == password;
  }

  static Future<void> _removeUserCredentials(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password_${email.toLowerCase()}');
  }

  // Check if any admin exists
  static Future<bool> hasAdminAccount() async {
    final users = await getAllUsers();
    return users.any((user) => user.role == 'Admin');
  }

  // Create default admin account if none exists
  static Future<AuthResult> createDefaultAdmin() async {
    try {
      final hasAdmin = await hasAdminAccount();
      if (hasAdmin) {
        return AuthResult(
          success: false,
          message: 'Admin account already exists',
        );
      }

      return await register(
        name: 'System Administrator',
        email: 'admin@mandal.com',
        phone: '1234567890',
        password: 'admin123',
        role: 'Admin',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to create default admin: ${e.toString()}',
      );
    }
  }

  // Get users by role
  static Future<List<User>> getUsersByRole(String role) async {
    final users = await getAllUsers();
    return users.where((user) => user.role == role).toList();
  }

  // Promote user to admin/manager
  static Future<AuthResult> promoteUser({
    required String userId,
    required String newRole,
  }) async {
    try {
      final users = await getAllUsers();
      final userIndex = users.indexWhere((user) => user.id == userId);
      
      if (userIndex == -1) {
        return AuthResult(
          success: false,
          message: 'User not found',
        );
      }

      final user = users[userIndex];
      final updatedUser = User(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: newRole,
      );

      users[userIndex] = updatedUser;
      await _saveAllUsers(users);

      return AuthResult(
        success: true,
        message: 'User role updated successfully',
        user: updatedUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update user role: ${e.toString()}',
      );
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}