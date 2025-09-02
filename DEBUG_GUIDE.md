# 🐛 Supabase Debug Guide

## What I've Implemented

### 1. ✅ Updated Supabase Configuration
- **File**: `lib/config/supabase_config.dart`
- **Changes**: Added your actual Supabase URL and API key
- **Status**: Ready to connect to your database

### 2. ✅ Enhanced Authentication Service
- **File**: `lib/services/supabase_auth_service.dart`
- **Changes**: 
  - Removed bypass mode (`SUPABASE_AUTH_DISABLED = false`)
  - Added comprehensive debug logging with emojis
  - Added connection testing method
  - Enhanced error handling and reporting

### 3. ✅ Enhanced Supabase Service
- **File**: `lib/services/supabase_service.dart`
- **Changes**:
  - Added debug logging for initialization
  - Added connection testing on startup
  - Better error reporting

### 4. ✅ Created Debug Screen
- **File**: `lib/debug/debug_screen.dart`
- **Features**:
  - Test Supabase connection
  - Test user registration
  - Test user login
  - Get current user info
  - Get all users
  - Real-time debug output with timestamps

### 5. ✅ Added Debug Button
- **File**: `lib/AuthenticationScreen/AuthWrapper.dart`
- **Changes**: Added floating debug button (🐛) that only appears in debug mode

### 6. ✅ Updated Database Schema
- **File**: `supabase_schema.sql`
- **Changes**: 
  - Updated to work with Supabase Auth (UUID instead of BIGSERIAL)
  - Added trigger to auto-create user profiles
  - Proper foreign key relationships

## 🚀 How to Debug Data Flow

### Step 1: Setup Database
1. Go to https://supabase.com/dashboard
2. Open your project: `lgmeeingeisketzfutyy`
3. Go to SQL Editor
4. Copy and paste the entire `supabase_schema.sql` content
5. Click "Run"

### Step 2: Run Your App
```bash
flutter run
```

### Step 3: Access Debug Screen
- Look for the small red debug button (🐛) in the bottom right corner
- Tap it to open the Debug Screen

### Step 4: Test Connection
1. Click "Test Connection" button
2. Watch the debug output for:
   - ✅ Connection successful
   - ❌ Connection failed (with error details)

### Step 5: Test Registration
1. Fill in the form fields:
   - Name: Test User
   - Email: test@example.com
   - Phone: 1234567890
   - Password: test123
2. Click "Test Register"
3. Watch for debug messages like:
   - 🚀 Starting user registration...
   - 🔐 Registering with Supabase Auth...
   - 💾 Creating user profile in database...
   - ✅ Registration completed successfully!

### Step 6: Verify in Supabase Dashboard
1. Go back to Supabase Dashboard
2. Click "Table Editor"
3. Select "users" table
4. Check if your test user appears

### Step 7: Test Login
1. Use the same email/password from registration
2. Click "Test Login"
3. Watch for:
   - 🔑 Starting user login...
   - 👤 Fetching user profile...
   - 🎉 Login completed successfully!

## 🔍 Debug Output Meanings

| Emoji | Meaning |
|-------|---------|
| 🚀 | Starting an operation |
| ✅ | Success |
| ❌ | Error/Failure |
| 🔍 | Debug information |
| 📧 | Email related |
| 👤 | User related |
| 💾 | Database operation |
| 🔑 | Authentication |
| 🆔 | User ID |
| 📱 | Phone related |
| 🎭 | Role related |
| 🧪 | Testing |
| ⚠️ | Warning |

## 🔧 Common Issues and Solutions

### Issue: "Connection test failed"
**Possible Causes:**
- Internet connection problem
- Wrong Supabase URL/key
- Supabase project is paused

**Debug Steps:**
1. Check console output for specific error
2. Verify URL and key in `supabase_config.dart`
3. Check Supabase project status

### Issue: "Registration failed: No user returned"
**Possible Causes:**
- Email already exists
- Email confirmation required
- Invalid email format

**Debug Steps:**
1. Try different email
2. Check Supabase Auth settings
3. Look at detailed error message

### Issue: "Login failed: Invalid credentials"
**Possible Causes:**
- Wrong email/password
- User not confirmed
- User doesn't exist

**Debug Steps:**
1. Verify credentials
2. Check if registration was successful
3. Check Supabase Auth logs

### Issue: "Error getting current user"
**Possible Causes:**
- User profile not created in users table
- Database trigger not working
- User not authenticated

**Debug Steps:**
1. Check if user exists in auth.users
2. Check if user exists in public.users
3. Verify trigger is working

## 📊 Monitoring Data Flow

### Console Output
Watch your Flutter console for detailed logs:
```
🔧 [SupabaseService] 🚀 Initializing Supabase...
🔧 [SupabaseService] 🌐 URL: https://lgmeeingeisketzfutyy.supabase.co
🔧 [SupabaseService] ✅ Supabase initialized successfully
🔍 [SupabaseAuthService] 🚀 Starting user registration...
🔍 [SupabaseAuthService] 📧 Email: test@example.com
🔍 [SupabaseAuthService] 💾 Creating user profile in database...
🔍 [SupabaseAuthService] ✅ User profile created successfully
```

### Supabase Dashboard
Monitor in real-time:
1. **Auth > Users**: See authenticated users
2. **Table Editor > users**: See user profiles
3. **Logs**: See database operations
4. **API Logs**: See API calls

## 🎯 Next Steps After Successful Testing

1. **Create Admin User**: Register a user and update their role to 'Admin'
2. **Test App Features**: Use the main app functionality
3. **Disable Debug Mode**: Set `DEBUG_MODE = false` for production
4. **Remove Debug Button**: Comment out debug button for production

## 📞 Getting Help

If you encounter issues:
1. Share the debug output from the console
2. Share screenshots of the Debug Screen
3. Check Supabase Dashboard for any errors
4. Verify your database schema was created correctly