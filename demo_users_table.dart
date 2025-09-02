// Demo: Users Table System - No Authentication Service
// This demonstrates how the app now saves data directly to users table

import 'lib/services/user_table_service.dart';import 'lib/models/user.dart';

void main() async {
  print('🗄️  USERS TABLE DEMO');
  print('===================');
  print('✅ No authentication service required');
  print('✅ Direct table operations only');
  print('✅ All data stored locally\\n');

  // Step 1: Create users directly in table
  print('📝 STEP 1: Creating users in table...');
  await UserTableService.createUser(
    name: 'Alice Smith',
    email: 'alice@example.com',
    phone: '+1234567890',
    password: 'password123', // Stored but not used for auth
    role: 'Member',
  );

  await UserTableService.createUser(
    name: 'Bob Johnson',
    email: 'bob@example.com',
    phone: '+0987654321',
    password: 'password456',
    role: 'Admin',
  );

  // Step 2: Show all users in table
  print('\\n📊 STEP 2: Viewing users table...');
  final allUsers = await UserTableService.getAllUsers();
  print('Total users in table: ${allUsers.length}');
  
  for (int i = 0; i < allUsers.length; i++) {
    final user = allUsers[i];
    print('User ${i + 1}:');
    print('  - ID: ${user.id}');
    print('  - Name: ${user.name}');
    print('  - Email: ${user.email}');
    print('  - Phone: ${user.phone}');
    print('  - Role: ${user.role}');
  }

  // Step 3: Login (just set current user from table)
  print('\\n🔑 STEP 3: Login (find user in table)...');
  final loginResult = await UserTableService.loginUser(
    email: 'alice@example.com',
    password: 'ignored', // Password not checked
  );
  print('Login result: ${loginResult['success']}');
  print('Message: ${loginResult['message']}');

  // Step 4: Check current user
  print('\\n👤 STEP 4: Current logged-in user...');
  final currentUser = await UserTableService.getCurrentUser();
  print('Current user: ${currentUser?.name}');
  print('Email: ${currentUser?.email}');

  // Step 5: Update user in table
  print('\\n✏️  STEP 5: Updating user in table...');
  if (currentUser != null) {
    final updateResult = await UserTableService.updateUser(
      userId: currentUser.id,
      name: 'Alice Johnson (Updated)',
      phone: '+1111111111',
    );
    print('Update result: ${updateResult['success']}');
    print('Updated user: ${updateResult['user']?.name}');
  }

  // Step 6: Show final table state
  print('\\n📋 STEP 6: Final users table state...');
  final finalUsers = await UserTableService.getAllUsers();
  for (final user in finalUsers) {
    print('- ${user.name} (${user.email}) - ${user.role}');
  }

  // Step 7: System info
  print('\\n🔍 STEP 7: System information...');
  final systemInfo = UserTableService.getSystemInfo();
  systemInfo.forEach((key, value) {
    print('$key: $value');
  });

  print('\\n🎉 DEMO COMPLETED!');
  print('✅ All operations performed directly on users table');
  print('✅ No email verification needed');
  print('✅ No authentication service required');
  print('✅ Simple table-based user management');
}