import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'supabase_service.dart';

class CustomAuthService {
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

  // Register new user in Supabase users table
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'Member',
  }) async {
    try {
      // Check if user already exists
      final existingUsers = await SupabaseService.select(
        'users',
        filters: {'email': email.toLowerCase()},
      );
      
      if (existingUsers.isNotEmpty) {
        return AuthResult(
          success: false,
          message: 'User with this email already exists',
        );
      }

      // Hash password
      final hashedPassword = _hashPassword(password);
      
      // Create user data
      final userData = {
        'name': name,
        'email': email.toLowerCase(),
        'phone': phone,
        'password_hash': hashedPassword,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert user into Supabase
      final insertedUsers = await SupabaseService.insert('users', userData);
      
      if (insertedUsers.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Failed to create user account',
        );
      }

      final insertedUser = insertedUsers.first;
      final user = User(
        id: insertedUser['id'].toString(),
        name: insertedUser['name'],
        email: insertedUser['email'],
        phone: insertedUser['phone'],
        role: insertedUser['role'],
      );

      // Set as current user locally
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

  // Login user using Supabase users table
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Get user from Supabase
      final users = await SupabaseService.select(
        'users',
        filters: {'email': email.toLowerCase()},
      );

      if (users.isEmpty) {
        return AuthResult(
          success: false,
          message: 'No account found with this email',
        );
      }

      final userData = users.first;
      
      // Verify password
      final hashedPassword = _hashPassword(password);
      if (userData['password_hash'] != hashedPassword) {
        return AuthResult(
          success: false,
          message: 'Invalid password',
        );
      }

      final user = User(
        id: userData['id'].toString(),
        name: userData['name'],
        email: userData['email'],
        phone: userData['phone'],
        role: userData['role'],
      );

      // Set as current user locally
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

  // Update user profile in Supabase
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

      // Update user in Supabase
      final updateData = {
        'name': name,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.update(
        'users',
        updateData,
        filters: {'id': int.parse(currentUser.id)},
      );

      // Create updated user
      final updatedUser = User(
        id: currentUser.id,
        name: name,
        email: currentUser.email,
        phone: phone,
        role: currentUser.role,
      );

      // Update current user locally
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

  // Change password in Supabase
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

      // Verify current password
      final users = await SupabaseService.select(
        'users',
        filters: {'id': int.parse(currentUser.id)},
      );

      if (users.isEmpty) {
        return AuthResult(
          success: false,
          message: 'User not found',
        );
      }

      final userData = users.first;
      final currentHashedPassword = _hashPassword(currentPassword);
      
      if (userData['password_hash'] != currentHashedPassword) {
        return AuthResult(
          success: false,
          message: 'Current password is incorrect',
        );
      }

      // Update password in Supabase
      final newHashedPassword = _hashPassword(newPassword);
      await SupabaseService.update(
        'users',
        {
          'password_hash': newHashedPassword,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': int.parse(currentUser.id)},
      );

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

  // Reset password (generate temporary password)
  static Future<AuthResult> resetPassword({
    required String email,
  }) async {
    try {
      final users = await SupabaseService.select(
        'users',
        filters: {'email': email.toLowerCase()},
      );

      if (users.isEmpty) {
        return AuthResult(
          success: false,
          message: 'No account found with this email',
        );
      }

      // Generate temporary password
      final tempPassword = 'temp${DateTime.now().millisecondsSinceEpoch}';
      final hashedTempPassword = _hashPassword(tempPassword);

      // Update password in Supabase
      await SupabaseService.update(
        'users',
        {
          'password_hash': hashedTempPassword,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'email': email.toLowerCase()},
      );

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

  // Get all registered users from Supabase
  static Future<List<User>> getAllUsers() async {
    try {
      final users = await SupabaseService.select('users');
      return users.map((u) => User(
        id: u['id'].toString(),
        name: u['name'],
        email: u['email'],
        phone: u['phone'],
        role: u['role'],
      )).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Get users by role from Supabase
  static Future<List<User>> getUsersByRole(String role) async {
    try {
      final users = await SupabaseService.select(
        'users',
        filters: {'role': role},
      );
      return users.map((u) => User(
        id: u['id'].toString(),
        name: u['name'],
        email: u['email'],
        phone: u['phone'],
        role: u['role'],
      )).toList();
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
    }
  }

  // Promote user to admin/manager in Supabase
  static Future<AuthResult> promoteUser({
    required String userId,
    required String newRole,
  }) async {
    try {
      await SupabaseService.update(
        'users',
        {
          'role': newRole,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': int.parse(userId)},
      );

      return AuthResult(
        success: true,
        message: 'User role updated successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update user role: ${e.toString()}',
      );
    }
  }

  // Check if any admin exists in Supabase
  static Future<bool> hasAdminAccount() async {
    try {
      final admins = await getUsersByRole('Admin');
      return admins.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Create default admin account in Supabase
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

  // Private helper methods
  static Future<void> _setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  static String _hashPassword(String password) {
    // Simple hash for demo - in production use bcrypt or similar
    final bytes = utf8.encode(password + 'mandal_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

// AuthResult class for authentication operations
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