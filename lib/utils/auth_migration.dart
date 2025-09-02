import '../models/user.dart';
import '../services/user_table_service.dart';
import '../services/data_service.dart';
import '../services/shared_preferences_service.dart';

class AuthMigration {
  // Using simple users table - no authentication service needed
  static const bool USING_USERS_TABLE = true;

  // Check authentication status
  static Future<bool> isLoggedIn() async {
    return await UserTableService.isLoggedIn();
  }

  // Get current user from users table
  static Future<User?> getCurrentUser() async {
    return await UserTableService.getCurrentUser();
  }

  // Login using users table - just find user by email
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await UserTableService.loginUser(
        email: email,
        password: password, // Not used for authentication
      );
      
      return AuthResult(
        success: result['success'],
        message: result['message'],
        user: result['user'],
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Register using users table - direct insert
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'Member',
  }) async {
    try {
      final result = await UserTableService.createUser(
        name: name,
        email: email,
        phone: phone,
        password: password, // Stored but not used for auth
        role: role,
      );
      
      return AuthResult(
        success: result['success'],
        message: result['message'],
        user: result['user'],
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // Logout - clear current user everywhere
  static Future<void> logout() async {
    await UserTableService.clearCurrentUser();
    await DataService.clearCurrentUser();
    await SharedPreferencesService.clearLoginData();
  }

  // Update profile in users table
  static Future<AuthResult> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final currentUser = await UserTableService.getCurrentUser();
      if (currentUser == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }
      
      final result = await UserTableService.updateUser(
        userId: currentUser.id,
        name: name,
        phone: phone,
      );
      
      return AuthResult(
        success: result['success'],
        message: result['message'],
        user: result['user'],
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Profile update failed: ${e.toString()}',
      );
    }
  }

  // Reset password - not needed for table-based system
  static Future<AuthResult> resetPassword({
    required String email,
  }) async {
    return AuthResult(
      success: true,
      message: 'Password reset not needed - using users table only',
    );
  }

  // Get all users from table
  static Future<List<User>> getAllUsers() async {
    return await UserTableService.getAllUsers();
  }

  // Check if admin account exists in users table
  static Future<bool> hasAdminAccount() async {
    final users = await UserTableService.getAllUsers();
    return users.any((user) => user.role == 'Admin');
  }

  // Promote user in users table
  static Future<AuthResult> promoteUser({
    required String userId,
    required String newRole,
  }) async {
    try {
      final result = await UserTableService.updateUser(
        userId: userId,
        role: newRole,
      );
      
      return AuthResult(
        success: result['success'],
        message: result['message'],
        user: result['user'],
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'User promotion failed: ${e.toString()}',
      );
    }
  }

  // Change password - not needed for table-based system
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return AuthResult(
      success: true,
      message: 'Password change not needed - using users table only',
    );
  }

  // Delete account from users table
  static Future<AuthResult> deleteAccount({
    required String password,
  }) async {
    try {
      final currentUser = await UserTableService.getCurrentUser();
      if (currentUser == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }
      
      final result = await UserTableService.deleteUser(currentUser.id);
      
      return AuthResult(
        success: result['success'],
        message: result['message'],
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Account deletion failed: ${e.toString()}',
      );
    }
  }

  // Get system info for debugging
  static Map<String, dynamic> getSystemInfo() {
    return UserTableService.getSystemInfo();
  }
}

// Simple result class for auth operations
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