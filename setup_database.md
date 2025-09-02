# Quick Database Setup Guide

## Step 1: Run the Database Schema

1. Open your Supabase Dashboard: https://supabase.com/dashboard
2. Go to your project: `lgmeeingeisketzfutyy`
3. Click on "SQL Editor" in the left sidebar
4. Copy the entire content from `supabase_schema.sql` file
5. Paste it into the SQL Editor
6. Click "Run" button

## Step 2: Test the Connection

1. Run your Flutter app: `flutter run`
2. You'll see a small red debug button (🐛) in the bottom right corner
3. Tap the debug button to open the Debug Screen
4. Click "Test Connection" to verify Supabase is working

## Step 3: Test User Registration

1. In the Debug Screen, fill in:
   - Name: Test User
   - Email: test@example.com
   - Phone: 1234567890
   - Password: test123
2. Click "Test Register"
3. Check the debug output for success/error messages

## Step 4: Verify Data in Supabase

1. Go back to Supabase Dashboard
2. Click "Table Editor" in the left sidebar
3. Select "users" table
4. You should see your test user data

## Step 5: Test Login

1. In the Debug Screen, use the same email/password
2. Click "Test Login"
3. Check if login is successful

## Debug Output Meanings

- 🚀 = Starting an operation
- ✅ = Success
- ❌ = Error/Failure
- 🔍 = Debug information
- 📧 = Email related
- 👤 = User related
- 💾 = Database operation
- 🔑 = Authentication

## Common Issues and Solutions

### "Connection test failed"
- Check your internet connection
- Verify Supabase URL and key are correct
- Make sure Supabase project is active

### "Registration failed: No user returned"
- Email might already exist
- Check Supabase Auth settings
- Verify email confirmation is not required

### "Login failed: Invalid credentials"
- Check email/password are correct
- User might not be confirmed yet
- Check Supabase Auth logs

### "Error getting current user"
- User profile might not exist in users table
- Check if the trigger is working properly
- Manually check users table in Supabase

## Next Steps After Successful Testing

1. Create your first admin user
2. Update the user's role to 'Admin' in Supabase
3. Start using the app normally
4. Remove or disable debug mode for production