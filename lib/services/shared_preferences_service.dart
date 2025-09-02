import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart' as AppUser;

/// SharedPreferences Service for storing user login data and app preferences
/// 
/// Features:
/// - Store and retrieve user login credentials
/// - Remember login state
/// - Store user profile data locally
/// - Auto-login functionality
/// - Secure data storage with JSON serialization
class SharedPreferencesService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserData = 'user_data';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyLastLoginEmail = 'last_login_email';
  static const String _keyLoginTimestamp = 'login_timestamp';
  static const String _keyAppVersion = 'app_version';
  
  static SharedPreferences? _prefs;
  
  /// Initialize SharedPreferences
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Ensure SharedPreferences is initialized
  static Future<SharedPreferences> get _instance async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }
  
  // ==================== LOGIN STATE MANAGEMENT ====================
  
  /// Save user login state and data
  static Future<bool> saveLoginData({
    required AppUser.User user,
    bool rememberMe = false,
  }) async {
    try {
      final prefs = await _instance;
      
      // Save login state
      await prefs.setBool(_keyIsLoggedIn, true);
      
      // Save user data as JSON
      final userJson = json.encode(user.toJson());
      await prefs.setString(_keyUserData, userJson);
      
      // Save remember me preference
      await prefs.setBool(_keyRememberMe, rememberMe);
      
      // Save last login email
      await prefs.setString(_keyLastLoginEmail, user.email);
      
      // Save login timestamp
      await prefs.setString(_keyLoginTimestamp, DateTime.now().toIso8601String());
      
      print('✅ Login data saved to SharedPreferences');
      print('👤 User: ${user.name} (${user.email})');
      print('🔒 Remember Me: $rememberMe');
      
      return true;
    } catch (e) {
      print('❌ Error saving login data: $e');
      return false;
    }
  }
  
  /// Get stored user data
  static Future<AppUser.User?> getStoredUser() async {
    try {
      final prefs = await _instance;
      final userJson = prefs.getString(_keyUserData);
      
      if (userJson == null) {
        print('ℹ️ No stored user data found');
        return null;
      }
      
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      final user = AppUser.User.fromJson(userMap);
      
      print('✅ Retrieved stored user: ${user.name} (${user.email})');
      return user;
    } catch (e) {
      print('❌ Error retrieving stored user: $e');
      return null;
    }
  }
  
  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await _instance;
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (isLoggedIn) {
        // Check if login is still valid (optional: add expiration logic)
        final user = await getStoredUser();
        if (user == null) {
          // Clear invalid login state
          await clearLoginData();
          return false;
        }
      }
      
      return isLoggedIn;
    } catch (e) {
      print('❌ Error checking login state: $e');
      return false;
    }
  }
  
  /// Check if remember me is enabled
  static Future<bool> shouldRememberLogin() async {
    try {
      final prefs = await _instance;
      return prefs.getBool(_keyRememberMe) ?? false;
    } catch (e) {
      print('❌ Error checking remember me: $e');
      return false;
    }
  }
  
  /// Get last login email
  static Future<String?> getLastLoginEmail() async {
    try {
      final prefs = await _instance;
      return prefs.getString(_keyLastLoginEmail);
    } catch (e) {
      print('❌ Error getting last login email: $e');
      return null;
    }
  }
  
  /// Get login timestamp
  static Future<DateTime?> getLoginTimestamp() async {
    try {
      final prefs = await _instance;
      final timestampString = prefs.getString(_keyLoginTimestamp);
      
      if (timestampString == null) return null;
      
      return DateTime.parse(timestampString);
    } catch (e) {
      print('❌ Error getting login timestamp: $e');
      return null;
    }
  }
  
  /// Clear all login data (logout)
  static Future<bool> clearLoginData() async {
    try {
      final prefs = await _instance;
      
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserData);
      await prefs.remove(_keyLoginTimestamp);
      // Keep remember me and last email for convenience
      
      print('✅ Login data cleared from SharedPreferences');
      return true;
    } catch (e) {
      print('❌ Error clearing login data: $e');
      return false;
    }
  }
  
  /// Complete logout (clear everything)
  static Future<bool> completeLogout() async {
    try {
      final prefs = await _instance;
      
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserData);
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyLastLoginEmail);
      await prefs.remove(_keyLoginTimestamp);
      
      print('✅ Complete logout - all data cleared');
      return true;
    } catch (e) {
      print('❌ Error during complete logout: $e');
      return false;
    }
  }
  
  // ==================== USER PROFILE MANAGEMENT ====================
  
  /// Update stored user profile
  static Future<bool> updateUserProfile(AppUser.User updatedUser) async {
    try {
      final prefs = await _instance;
      final userJson = json.encode(updatedUser.toJson());
      await prefs.setString(_keyUserData, userJson);
      
      print('✅ User profile updated in SharedPreferences');
      return true;
    } catch (e) {
      print('❌ Error updating user profile: $e');
      return false;
    }
  }
  
  // ==================== APP PREFERENCES ====================
  
  /// Save app version
  static Future<void> saveAppVersion(String version) async {
    try {
      final prefs = await _instance;
      await prefs.setString(_keyAppVersion, version);
    } catch (e) {
      print('❌ Error saving app version: $e');
    }
  }
  
  /// Get app version
  static Future<String?> getAppVersion() async {
    try {
      final prefs = await _instance;
      return prefs.getString(_keyAppVersion);
    } catch (e) {
      print('❌ Error getting app version: $e');
      return null;
    }
  }
  
  // ==================== UTILITY METHODS ====================
  
  /// Get all stored keys (for debugging)
  static Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await _instance;
      return prefs.getKeys();
    } catch (e) {
      print('❌ Error getting all keys: $e');
      return <String>{};
    }
  }
  
  /// Clear all app data (for debugging/reset)
  static Future<bool> clearAllData() async {
    try {
      final prefs = await _instance;
      await prefs.clear();
      print('✅ All SharedPreferences data cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing all data: $e');
      return false;
    }
  }
  
  /// Print debug information
  static Future<void> printDebugInfo() async {
    try {
      print('\n🔍 SharedPreferences Debug Info:');
      print('Is Logged In: ${await isLoggedIn()}');
      print('Remember Me: ${await shouldRememberLogin()}');
      print('Last Email: ${await getLastLoginEmail()}');
      print('Login Time: ${await getLoginTimestamp()}');
      
      final user = await getStoredUser();
      if (user != null) {
        print('Stored User: ${user.name} (${user.email}) - ${user.role}');
      } else {
        print('No stored user data');
      }
      
      print('All Keys: ${await getAllKeys()}');
      print('🔍 End Debug Info\n');
    } catch (e) {
      print('❌ Error printing debug info: $e');
    }
  }
}