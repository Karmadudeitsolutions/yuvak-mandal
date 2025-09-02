// Test Script for Login System
// Run this to test the SharedPreferences and Authentication integration

import 'package:flutter/material.dart';
import 'lib/services/shared_preferences_service.dart';
import 'lib/services/supabase_auth_service.dart';
import 'lib/models/user.dart' as AppUser;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing Login System Components...\n');
  
  // Test 1: SharedPreferences Initialization
  print('📋 Test 1: SharedPreferences Initialization');
  try {
    await SharedPreferencesService.initialize();
    print('✅ SharedPreferences initialized successfully');
  } catch (e) {
    print('❌ SharedPreferences initialization failed: $e');
  }
  
  // Test 2: Check initial login state
  print('\n📋 Test 2: Initial Login State');
  try {
    final isLoggedIn = await SharedPreferencesService.isLoggedIn();
    final lastEmail = await SharedPreferencesService.getLastLoginEmail();
    final rememberMe = await SharedPreferencesService.shouldRememberLogin();
    
    print('Is Logged In: $isLoggedIn');
    print('Last Email: $lastEmail');
    print('Remember Me: $rememberMe');
    print('✅ Login state check completed');
  } catch (e) {
    print('❌ Login state check failed: $e');
  }
  
  // Test 3: Create test user data
  print('\n📋 Test 3: Test User Data Creation');
  try {
    final testUser = AppUser.User(
      id: 'test-uuid-12345',
      name: 'Test User',
      email: 'test@example.com',
      phone: '1234567890',
      role: 'Member',
    );
    
    print('Test User Created:');
    print('- Name: ${testUser.name}');
    print('- Email: ${testUser.email}');
    print('- Role: ${testUser.role}');
    print('✅ Test user data created successfully');
  } catch (e) {
    print('❌ Test user creation failed: $e');
  }
  
  // Test 4: Save and retrieve user data
  print('\n📋 Test 4: Save and Retrieve User Data');
  try {
    final testUser = AppUser.User(
      id: 'test-uuid-12345',
      name: 'Test User',
      email: 'test@example.com',
      phone: '1234567890',
      role: 'Member',
    );
    
    // Save user data
    await SharedPreferencesService.saveLoginData(
      user: testUser,
      rememberMe: true,
    );
    print('✅ User data saved');
    
    // Retrieve user data
    final retrievedUser = await SharedPreferencesService.getStoredUser();
    if (retrievedUser != null) {
      print('✅ User data retrieved successfully');
      print('- Retrieved Name: ${retrievedUser.name}');
      print('- Retrieved Email: ${retrievedUser.email}');
      print('- Retrieved Role: ${retrievedUser.role}');
    } else {
      print('❌ Failed to retrieve user data');
    }
  } catch (e) {
    print('❌ Save/retrieve test failed: $e');
  }
  
  // Test 5: Authentication Service Initialization
  print('\n📋 Test 5: Authentication Service Initialization');
  try {
    await SupabaseAuthService.initializeAuth();
    print('✅ Authentication service initialized');
    print('Is Logged In: ${SupabaseAuthService.isLoggedIn}');
  } catch (e) {
    print('❌ Authentication service initialization failed: $e');
  }
  
  // Test 6: Clear test data
  print('\n📋 Test 6: Cleanup Test Data');
  try {
    await SharedPreferencesService.clearLoginData();
    print('✅ Test data cleared successfully');
  } catch (e) {
    print('❌ Cleanup failed: $e');
  }
  
  // Test 7: Debug information
  print('\n📋 Test 7: Debug Information');
  try {
    await SharedPreferencesService.printDebugInfo();
    print('✅ Debug information printed');
  } catch (e) {
    print('❌ Debug info failed: $e');
  }
  
  print('\n🎉 Login System Testing Completed!');
  print('\n📝 Next Steps:');
  print('1. Run the database fix script in Supabase');
  print('2. Test registration with the updated system');
  print('3. Test login with remember me functionality');
  print('4. Verify session persistence across app restarts');
}

// Helper function to simulate app restart
Future<void> simulateAppRestart() async {
  print('\n🔄 Simulating App Restart...');
  
  // This would normally happen on app start
  await SupabaseAuthService.initializeAuth();
  
  if (SupabaseAuthService.isLoggedIn) {
    print('✅ User session restored after restart');
    final user = await SharedPreferencesService.getStoredUser();
    if (user != null) {
      print('👤 Welcome back: ${user.name}');
    }
  } else {
    print('ℹ️ No active session found');
  }
}