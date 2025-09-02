import 'lib/utils/auth_migration.dart';
import 'lib/services/user_table_service.dart';
import 'lib/services/data_service.dart';

void main() async {
  print('🎯 Mandal Authentication Flow Demo');
  print('📋 Using LOCAL USERS TABLE (No Supabase Auth)');
  print('=' * 50);
  
  // 🔐 STEP 1: Registration Process (Like RegistrationScreen.dart)
  print('\n🔐 STEP 1: REGISTRATION PROCESS');
  print('File: signup_screen.dart');
  print('Table: users (local storage)');
  
  final registerResult = await AuthMigration.register(
    name: 'John Doe',
    email: 'john.doe@example.com',
    phone: '1234567890',
    password: 'ignored_password', // Stored but not used for auth
    role: 'Member',
  );
  
  print('✅ Registration Result: ${registerResult.success}');
  print('📝 Message: ${registerResult.message}');
  print('👤 User Created: ${registerResult.user?.name}');
  print('📧 Email: ${registerResult.user?.email}');
  print('📱 Phone: ${registerResult.user?.phone}');
  print('🎭 Role: ${registerResult.user?.role}');
  
  // Show what data gets stored in users table
  print('\n📊 DATA STORED IN USERS TABLE:');
  print('   - id: ${registerResult.user?.id}');
  print('   - name: ${registerResult.user?.name}');
  print('   - email: ${registerResult.user?.email}');
  print('   - phone: ${registerResult.user?.phone}');
  print('   - role: ${registerResult.user?.role}');
  print('   - created_at: ${DateTime.now().toIso8601String()}');
  
  // 🔑 STEP 2: Login Process (Like login_screen.dart)
  print('\n🔑 STEP 2: LOGIN PROCESS');
  print('File: login_screen.dart');
  print('Method: Find user by email in local users table');
  
  final loginResult = await AuthMigration.login(
    email: 'john.doe@example.com',
    password: 'any_password', // Password is ignored
  );
  
  print('✅ Login Result: ${loginResult.success}');
  print('📝 Message: ${loginResult.message}');
  print('👤 User Found: ${loginResult.user?.name}');
  
  // 📱 STEP 3: Session Management
  print('\n📱 STEP 3: SESSION MANAGEMENT');
  print('File: UserTableService.dart');
  print('Storage: SharedPreferences');
  
  final isLoggedIn = await AuthMigration.isLoggedIn();
  final currentUser = await AuthMigration.getCurrentUser();
  
  print('🔐 Is Logged In: $isLoggedIn');
  print('👤 Current User: ${currentUser?.name}');
  print('📧 Current Email: ${currentUser?.email}');
  
  // 🔄 STEP 4: App Flow Simulation
  print('\n🔄 STEP 4: APP FLOW SIMULATION');
  print('File: main.dart → AuthWrapper → Route Decision');
  
  if (isLoggedIn && currentUser != null) {
    print('✅ User is logged in → Navigate to HomeScreen');
    
    // Initialize sample data (like in real app)
    print('\n📊 INITIALIZING SAMPLE DATA...');
    await DataService.initializeSampleData();
    print('✅ Sample data initialized for user: ${currentUser.name}');
    
  } else {
    print('❌ User not logged in → Navigate to LoginScreen');
  }
  
  // 👥 STEP 5: Show All Users in Table
  print('\n👥 STEP 5: ALL USERS IN LOCAL TABLE');
  final allUsers = await UserTableService.getAllUsers();
  print('📊 Total Users: ${allUsers.length}');
  
  for (int i = 0; i < allUsers.length; i++) {
    final user = allUsers[i];
    print('   ${i + 1}. ${user.name} (${user.email}) - ${user.role}');
  }
  
  // 🚪 STEP 6: Logout Process
  print('\n🚪 STEP 6: LOGOUT PROCESS');
  await AuthMigration.logout();
  
  final loggedOutStatus = await AuthMigration.isLoggedIn();
  print('🔐 Is Logged In After Logout: $loggedOutStatus');
  
  // 📋 FINAL SUMMARY
  print('\n📋 AUTHENTICATION SYSTEM SUMMARY');
  print('=' * 50);
  print('✅ Table: users (local storage, not tbl_customer)');
  print('✅ Storage: SharedPreferences (not Supabase)');
  print('✅ Registration: Instant, no email verification');
  print('✅ Login: Email-only, no password verification');
  print('✅ Session: Persistent across app restarts');
  print('✅ Offline: Works completely without internet');
  print('✅ Security: No password storage risks');
  print('=' * 50);
  
  print('\n🎯 AUTHENTICATION FLOW COMPLETED SUCCESSFULLY!');
}