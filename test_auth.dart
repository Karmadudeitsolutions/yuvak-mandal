// Test script for custom authentication
// Run this to test your authentication system

import 'package:flutter/material.dart';
import 'lib/services/supabase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (you'll need to call your initialization code here)
  // await SupabaseService.initialize();
  
  print('🧪 Testing Custom Authentication System');
  print('=' * 50);
  
  // Test 1: Register a new user
  print('\n📝 Test 1: User Registration');
  final registerResult = await SupabaseAuthService.register(
    name: 'Test User',
    email: 'test@example.com',
    phone: '1234567890',
    password: 'testpassword123',
  );
  
  print('Registration Result: ${registerResult.success}');
  print('Message: ${registerResult.message}');
  if (registerResult.user != null) {
    print('User ID: ${registerResult.user!.id}');
    print('User Name: ${registerResult.user!.name}');
  }
  
  // Test 2: Login with the registered user
  print('\n🔑 Test 2: User Login');
  final loginResult = await SupabaseAuthService.login(
    email: 'test@example.com',
    password: 'testpassword123',
  );
  
  print('Login Result: ${loginResult.success}');
  print('Message: ${loginResult.message}');
  if (loginResult.user != null) {
    print('Logged in as: ${loginResult.user!.name}');
  }
  
  // Test 3: Check if user is logged in
  print('\n✅ Test 3: Authentication Status');
  print('Is Logged In: ${SupabaseAuthService.isLoggedIn}');
  
  final currentUser = await SupabaseAuthService.getCurrentUser();
  if (currentUser != null) {
    print('Current User: ${currentUser.name} (${currentUser.role})');
  }
  
  // Test 4: Update profile
  print('\n🔄 Test 4: Profile Update');
  final updateResult = await SupabaseAuthService.updateProfile(
    name: 'Updated Test User',
    phone: '9876543210',
  );
  
  print('Update Result: ${updateResult.success}');
  print('Message: ${updateResult.message}');
  
  // Test 5: Change password
  print('\n🔐 Test 5: Password Change');
  final passwordResult = await SupabaseAuthService.changePassword(
    currentPassword: 'testpassword123',
    newPassword: 'newpassword456',
  );
  
  print('Password Change Result: ${passwordResult.success}');
  print('Message: ${passwordResult.message}');
  
  // Test 6: Logout
  print('\n🚪 Test 6: Logout');
  await SupabaseAuthService.logout();
  print('Logout completed');
  print('Is Logged In: ${SupabaseAuthService.isLoggedIn}');
  
  print('\n🎉 Testing completed!');
}