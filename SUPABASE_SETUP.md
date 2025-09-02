# Supabase Setup Instructions

## 1. Database Setup

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `lgmeeingeisketzfutyy`
3. Go to the SQL Editor
4. Copy and paste the entire content of `supabase_schema.sql` into the SQL Editor
5. Click "Run" to execute the schema

## 2. Configuration

The Supabase configuration has been updated with your credentials:
- URL: `https://lgmeeingeisketzfutyy.supabase.co`
- Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## 3. Authentication Service

The `SupabaseAuthService` has been updated to use real Supabase authentication instead of bypass mode:

### Key Changes:
- `SUPABASE_AUTH_DISABLED = false` (authentication is now enabled)
- Uses Supabase Auth for user registration and login
- Stores additional user profile data in the `users` table
- Supports password reset via email
- Proper error handling and user feedback

### Features:
- ✅ User Registration with email/password
- ✅ User Login with email/password
- ✅ Password Reset via email
- ✅ User Profile Management
- ✅ Role-based Access (Member/Admin)
- ✅ User Management (get all users, promote users)

## 4. Database Schema

The database includes these tables:
- `users` - User profiles (extends Supabase Auth)
- `groups` - Mandal groups
- `group_members` - Group membership
- `contributions` - Monthly contributions
- `loan_requests` - Loan applications
- `repayments` - Loan repayments

## 5. Creating an Admin User

1. Register a new user through your app
2. Go to Supabase Dashboard > Table Editor > users
3. Find your user and update the `role` field to `'Admin'`

Or run this SQL in the SQL Editor:
```sql
UPDATE users SET role = 'Admin' WHERE email = 'your-email@example.com';
```

## 6. Testing the Connection

Run your Flutter app and try:
1. Registering a new user
2. Logging in with the registered user
3. The app should now connect to your Supabase database

## 7. Row Level Security (RLS)

The schema includes basic RLS policies. You may want to customize these based on your security requirements:
- Users can view and manage their own data
- Admins have broader access
- All operations are currently allowed (you can restrict as needed)

## 8. Troubleshooting

If you encounter issues:
1. Check the Flutter console for error messages
2. Verify your Supabase URL and key are correct
3. Ensure the database schema was created successfully
4. Check Supabase Dashboard > Authentication to see if users are being created

## 9. Next Steps

After setup:
1. Test user registration and login
2. Create your first admin user
3. Start using the loan management features
4. Customize RLS policies as needed for your security requirements