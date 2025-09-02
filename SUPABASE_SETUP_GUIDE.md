# Supabase Integration Setup Guide

## Overview
Your Flutter Mandal Loan System has been successfully integrated with Supabase! This guide will help you complete the setup and start using your cloud database.

## What's Been Added

### 1. Dependencies
- `supabase_flutter: ^2.8.0` - Main Supabase client
- `http: ^1.1.0` - HTTP client for API calls

### 2. Configuration Files
- `lib/config/supabase_config.dart` - Your Supabase credentials
- `lib/services/supabase_service.dart` - Core Supabase service wrapper
- `lib/services/supabase_auth_service.dart` - Authentication service
- `lib/services/supabase_data_service.dart` - Data operations service

### 3. Database Schema
- `database/supabase_schema.sql` - Complete database schema with tables, indexes, and security policies

### 4. Test Files
- `lib/test_supabase_connection.dart` - Connection test screen

## Setup Steps

### Step 1: Database Setup
1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Navigate to your project: https://lgmeeingeisketzfutyy.supabase.co
3. Go to **SQL Editor**
4. Copy and paste the contents of `database/supabase_schema.sql`
5. Click **Run** to execute the schema

### Step 2: Verify Connection
1. Run your Flutter app
2. Navigate to the test screen (you may need to add it to your navigation)
3. Check if the connection is successful

### Step 3: Update Your Existing Code
You can now choose to:
- **Option A**: Gradually migrate from local storage to Supabase
- **Option B**: Use both systems in parallel
- **Option C**: Completely switch to Supabase

## Database Tables Created

### 1. users
- Extends Supabase auth.users
- Stores user profiles (name, phone, role)
- Automatically created when users sign up

### 2. groups
- Loan groups/communities
- Managed by admins/managers

### 3. group_members
- Many-to-many relationship between users and groups
- Includes role within the group

### 4. contributions
- Monthly contributions by members
- Linked to groups and users

### 5. loan_requests
- Loan applications with approval workflow
- Tracks status, amount, purpose, interest

### 6. repayments
- Loan repayment records
- Linked to loan requests

## Security Features

### Row Level Security (RLS)
- Users can only see their own data
- Group members can see group data
- Admins have elevated permissions
- All policies are automatically enforced

### Authentication
- Email/password authentication
- Automatic user profile creation
- Role-based access control

## Usage Examples

### Authentication
```dart
// Register new user
final result = await SupabaseAuthService.register(
  name: 'John Doe',
  email: 'john@example.com',
  phone: '1234567890',
  password: 'securepassword',
  role: 'Member',
);

// Login
final loginResult = await SupabaseAuthService.login(
  email: 'john@example.com',
  password: 'securepassword',
);

// Check if logged in
bool isLoggedIn = SupabaseAuthService.isLoggedIn;
```

### Data Operations
```dart
// Get all groups
final groups = await SupabaseDataService.getGroups();

// Create contribution
final contribution = Contribution(
  id: '',
  groupId: 'group-id',
  userId: 'user-id',
  amount: 1000.0,
  description: 'Monthly contribution',
  date: DateTime.now(),
);
await SupabaseDataService.createContribution(contribution);

// Get user statistics
final stats = await SupabaseDataService.getUserStatistics('user-id');
```

## Migration Strategy

### Phase 1: Parallel Operation
- Keep existing local storage system
- Add Supabase operations alongside
- Test thoroughly with real data

### Phase 2: Gradual Migration
- Start using Supabase for new features
- Migrate existing data gradually
- Update UI to use Supabase data

### Phase 3: Complete Migration
- Remove local storage dependencies
- Update all screens to use Supabase
- Clean up old code

## Real-time Features

Your app now supports real-time updates:
- Live contribution updates
- Real-time loan status changes
- Instant notifications for group activities

## Environment Variables (Optional)

For better security, consider moving credentials to environment variables:

1. Create `.env` file (add to .gitignore)
```
SUPABASE_URL=https://lgmeeingeisketzfutyy.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

2. Use flutter_dotenv package to load them

## Troubleshooting

### Connection Issues
- Verify your Supabase URL and key
- Check internet connection
- Ensure Supabase project is active

### Database Errors
- Run the schema SQL in Supabase dashboard
- Check table names match your models
- Verify RLS policies are correct

### Authentication Issues
- Enable email authentication in Supabase Auth settings
- Check email confirmation settings
- Verify user creation triggers

## Next Steps

1. **Test the connection** using the test screen
2. **Set up the database** using the provided SQL schema
3. **Update your authentication screens** to use Supabase
4. **Migrate your data operations** gradually
5. **Add real-time features** to enhance user experience

## Support

If you encounter any issues:
1. Check the Supabase documentation: https://supabase.com/docs
2. Review the error messages in your Flutter console
3. Test individual operations using the provided service methods

Your Mandal Loan System is now ready for cloud-based operations with real-time synchronization, secure authentication, and scalable data management!