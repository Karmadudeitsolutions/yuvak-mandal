import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart' as AppUser;
import 'supabase_service.dart';
import 'shared_preferences_service.dart';

class SupabaseAuthService {
  static const bool SUPABASE_AUTH_DISABLED = true; // Now using custom auth
  static const bool DEBUG_MODE = true; // Enable detailed logging
  
  // UUID generator
  static const Uuid _uuid = Uuid();
  
  // Get Supabase client
  static SupabaseClient get _client => SupabaseService.client;
  
  // Debug logging helper
  static void _debugLog(String message) {
    if (DEBUG_MODE) {
      print('🔍 [SupabaseAuthService] $message');
    }
  }
  
  // Generate UUID
  static String _generateUuid() {
    return _uuid.v4();
  }
  
  // Hash password
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Verify password
  static bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword;
  }
  
  // Test connection to Supabase
  static Future<bool> testConnection() async {
    try {
      _debugLog('Testing Supabase connection...');
      
      // Try to fetch from a simple table or make a basic query
      final response = await _client
          .from('users')
          .select('count')
          .limit(1);
      
      _debugLog('✅ Connection test successful: $response');
      return true;
    } catch (e) {
      _debugLog('❌ Connection test failed: $e');
      return false;
    }
  }

  // Authentication Status
  static bool get isLoggedIn => _currentUser != null;
  
  // Initialize and restore login state from SharedPreferences
  static Future<void> initializeAuth() async {
    try {
      _debugLog('🔄 Initializing authentication...');
      
      // Initialize SharedPreferences
      await SharedPreferencesService.initialize();
      
      // Check if user was previously logged in
      final isLoggedIn = await SharedPreferencesService.isLoggedIn();
      
      if (isLoggedIn) {
        _debugLog('🔍 Found previous login session');
        
        // Restore user data from SharedPreferences
        final storedUser = await SharedPreferencesService.getStoredUser();
        
        if (storedUser != null) {
          _currentUser = storedUser;
          _debugLog('✅ Login session restored');
          _debugLog('👤 Welcome back: ${storedUser.name}');
        } else {
          _debugLog('⚠️ Invalid stored user data, clearing session');
          await SharedPreferencesService.clearLoginData();
        }
      } else {
        _debugLog('ℹ️ No previous login session found');
      }
    } catch (e) {
      _debugLog('❌ Error initializing auth: $e');
      print('Auth initialization error: $e');
    }
  }

  // Get Current User
  static Future<AppUser.User?> getCurrentUser() async {
    try {
      _debugLog('Getting current user...');
      
      if (_currentUser == null) {
        _debugLog('❌ No authenticated user found');
        return null;
      }
      
      _debugLog('✅ Current user: ${_currentUser!.name} (${_currentUser!.role})');
      return _currentUser;
    } catch (e) {
      _debugLog('❌ Error getting current user: $e');
      print('Error getting current user: $e');
      return null;
    }
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
      _debugLog('🚀 Starting user registration...');
      _debugLog('📧 Email: $email');
      _debugLog('👤 Name: $name');
      _debugLog('📱 Phone: $phone');
      _debugLog('🎭 Role: $role');
      
      // Check if email already exists
      _debugLog('🔍 Checking if email already exists...');
      final existingUser = await _client
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      if (existingUser != null) {
        _debugLog('❌ Email already exists');
        return AuthResult(
          success: false,
          message: 'Email already exists. Please use a different email.',
        );
      }
      
      // Generate UUID and hash password
      final userId = _generateUuid();
      final hashedPassword = _hashPassword(password);
      
      _debugLog('🆔 Generated User ID: $userId');
      _debugLog('🔐 Password hashed successfully');

      // Create user profile in users table
      final userProfile = {
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'password': hashedPassword,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      _debugLog('💾 Creating user profile in database...');
      final sanitizedProfile = Map<String, dynamic>.from(userProfile);
      sanitizedProfile.remove('password'); // Don't log password hash
      _debugLog('📊 Profile data: $sanitizedProfile');
      
      final insertResponse = await _client.from('users').insert(userProfile).select();
      _debugLog('✅ User profile created successfully: $insertResponse');

      final user = AppUser.User(
        id: userId,
        name: name,
        email: email,
        phone: phone,
        role: role,
      );

      _debugLog('🎉 Registration completed successfully!');
      return AuthResult(
        success: true,
        message: 'Registration successful',
        user: user,
      );
    } catch (e) {
      _debugLog('❌ Registration error: $e');
      _debugLog('🔍 Error type: ${e.runtimeType}');
      print('Registration error: $e');
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  // Current logged in user (stored in memory for this session)
  static AppUser.User? _currentUser;
  
  // Login user
  static Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      _debugLog('🔑 Starting user login...');
      _debugLog('📧 Email: $email');
      
      // Get user from database
      _debugLog('🔍 Fetching user from database...');
      final response = await _client
          .from('users')
          .select('id, name, email, phone, role, password')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        _debugLog('❌ User not found');
        return AuthResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      _debugLog('👤 User found: ${response['name']}');
      
      // Verify password
      final storedPasswordHash = response['password'] as String?;
      if (storedPasswordHash == null || !_verifyPassword(password, storedPasswordHash)) {
        _debugLog('❌ Password verification failed');
        return AuthResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      _debugLog('✅ Password verified successfully');

      // Create user object
      final user = AppUser.User(
        id: response['id'],
        name: response['name'],
        email: response['email'],
        phone: response['phone'] ?? '',
        role: response['role'] ?? 'Member',
      );

      // Store current user in memory
      _currentUser = user;
      
      // Save login data to SharedPreferences
      await SharedPreferencesService.saveLoginData(
        user: user,
        rememberMe: rememberMe,
      );
      
      _debugLog('🎉 Login completed successfully!');
      _debugLog('👤 Logged in as: ${user.name} (${user.role})');
      _debugLog('💾 Login data saved to SharedPreferences');
      
      return AuthResult(
        success: true,
        message: 'Login successful',
        user: user,
      );
    } catch (e) {
      _debugLog('❌ Login error: $e');
      _debugLog('🔍 Error type: ${e.runtimeType}');
      print('Login error: $e');
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Login user with email or phone
  static Future<AuthResult> loginWithEmailOrPhone({
    required String emailOrPhone,
    required bool isEmail,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      _debugLog('🔑 Starting user login with ${isEmail ? 'email' : 'phone'}...');
      _debugLog('📧/📱 ${isEmail ? 'Email' : 'Phone'}: $emailOrPhone');
      
      // Get user from database based on email or phone
      _debugLog('🔍 Fetching user from database...');
      final response = await _client
          .from('users')
          .select('id, name, email, phone, role, password')
          .eq(isEmail ? 'email' : 'phone', emailOrPhone)
          .maybeSingle();

      if (response == null) {
        _debugLog('❌ User not found');
        return AuthResult(
          success: false,
          message: 'Invalid ${isEmail ? 'email' : 'phone number'} or password',
        );
      }

      _debugLog('👤 User found: ${response['name']}');
      
      // Verify password
      final storedPasswordHash = response['password'] as String?;
      if (storedPasswordHash == null || !_verifyPassword(password, storedPasswordHash)) {
        _debugLog('❌ Password verification failed');
        return AuthResult(
          success: false,
          message: 'Invalid ${isEmail ? 'email' : 'phone number'} or password',
        );
      }

      _debugLog('✅ Password verified successfully');

      // Create user object
      final user = AppUser.User(
        id: response['id'],
        name: response['name'],
        email: response['email'],
        phone: response['phone'] ?? '',
        role: response['role'] ?? 'Member',
      );

      // Store current user in memory
      _currentUser = user;
      
      // Save login data to SharedPreferences (always save email for consistency)
      await SharedPreferencesService.saveLoginData(
        user: user,
        rememberMe: rememberMe,
      );
      
      _debugLog('🎉 Login completed successfully!');
      _debugLog('👤 Logged in as: ${user.name} (${user.role})');
      _debugLog('💾 Login data saved to SharedPreferences');
      
      return AuthResult(
        success: true,
        message: 'Login successful',
        user: user,
      );
    } catch (e) {
      _debugLog('❌ Login error: $e');
      _debugLog('🔍 Error type: ${e.runtimeType}');
      print('Login error: $e');
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      _debugLog('🚪 Logging out user...');
      
      // Clear SharedPreferences
      await SharedPreferencesService.clearLoginData();
      
      // Clear current user from memory
      _currentUser = null;
      
      _debugLog('✅ User logged out successfully');
      _debugLog('🗑️ Login data cleared from SharedPreferences');
    } catch (e) {
      _debugLog('❌ Logout error: $e');
      print('Logout error: $e');
    }
  }

  // Update user profile
  static Future<AuthResult> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      _debugLog('🔄 Updating user profile...');
      _debugLog('👤 Name: $name');
      _debugLog('📱 Phone: $phone');

      // Update user profile in users table
      final response = await _client
          .from('users')
          .update({
            'name': name,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id)
          .select()
          .single();

      final updatedUser = AppUser.User.fromJson(response);
      
      // Update current user in memory
      _currentUser = updatedUser;

      _debugLog('✅ Profile updated successfully');
      return AuthResult(
        success: true,
        message: 'Profile updated successfully',
        user: updatedUser,
      );
    } catch (e) {
      _debugLog('❌ Profile update error: $e');
      print('Profile update error: $e');
      return AuthResult(
        success: false,
        message: 'Profile update failed: ${e.toString()}',
      );
    }
  }

  // Reset password
  static Future<AuthResult> resetPassword({
    required String email,
  }) async {
    return AuthResult(
      success: false,
      message: 'Password reset is disabled. Please contact administrator.',
    );
  }

  // Get all registered users
  static Future<List<AppUser.User>> getAllUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return response
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get users by role
  static Future<List<AppUser.User>> getUsersByRole(String role) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);

      return response
          .map<AppUser.User>((json) => AppUser.User.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // Promote user
  static Future<AuthResult> promoteUser({
    required String userId,
    required String newRole,
  }) async {
    try {
      await _client
          .from('users')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return AuthResult(
        success: true,
        message: 'User promoted successfully',
      );
    } catch (e) {
      print('User promotion error: $e');
      return AuthResult(
        success: false,
        message: 'User promotion failed: ${e.toString()}',
      );
    }
  }

  // Change password
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _debugLog('🔐 Starting password change...');
      
      if (_currentUser == null) {
        _debugLog('❌ No user logged in');
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      _debugLog('🔍 Verifying current password...');
      
      // Get current password hash from database
      final response = await _client
          .from('users')
          .select('password')
          .eq('id', _currentUser!.id)
          .single();
      
      final currentPasswordHash = response['password'] as String;
      
      // Verify current password
      if (!_verifyPassword(currentPassword, currentPasswordHash)) {
        _debugLog('❌ Current password verification failed');
        return AuthResult(
          success: false,
          message: 'Current password is incorrect',
        );
      }

      _debugLog('🔄 Updating password...');
      
      // Hash new password and update in database
      final newPasswordHash = _hashPassword(newPassword);
      
      await _client
          .from('users')
          .update({
            'password': newPasswordHash,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id);

      _debugLog('✅ Password changed successfully');
      return AuthResult(
        success: true,
        message: 'Password changed successfully',
      );
    } catch (e) {
      _debugLog('❌ Password change error: $e');
      print('Password change error: $e');
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
      _debugLog('🗑️ Starting account deletion...');
      
      if (_currentUser == null) {
        _debugLog('❌ No user logged in');
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      _debugLog('🔐 Verifying password...');
      
      // Get current password hash from database
      final response = await _client
          .from('users')
          .select('password')
          .eq('id', _currentUser!.id)
          .single();
      
      final currentPasswordHash = response['password'] as String;
      
      // Verify password
      if (!_verifyPassword(password, currentPasswordHash)) {
        _debugLog('❌ Password verification failed');
        return AuthResult(
          success: false,
          message: 'Password is incorrect',
        );
      }

      _debugLog('💾 Deleting user profile from database...');
      // Delete user profile from users table
      await _client
          .from('users')
          .delete()
          .eq('id', _currentUser!.id);

      _debugLog('🚪 Logging out user...');
      // Clear current user
      _currentUser = null;

      _debugLog('✅ Account deletion completed');
      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } catch (e) {
      _debugLog('❌ Account deletion error: $e');
      print('Account deletion error: $e');
      return AuthResult(
        success: false,
        message: 'Account deletion failed: ${e.toString()}',
      );
    }
  }

  // Check if any admin exists
  static Future<bool> hasAdminAccount() async {
    try {
      final response = await _client
          .from('users')
          .select('id')
          .eq('role', 'Admin')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking admin account: $e');
      return false;
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final AppUser.User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}