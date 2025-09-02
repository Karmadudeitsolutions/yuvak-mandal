// Supabase Configuration
// Replace these values with your actual Supabase project credentials

class SupabaseConfig {
  // Get these values from your Supabase Dashboard > Settings > API
  static const String supabaseUrl = 'https://lgmeeingeisketzfutyy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnbWVlaW5nZWlza2V0emZ1dHl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1MjczNjksImV4cCI6MjA3MjEwMzM2OX0.29FEdMXdL4pOsns_4-XkIb56qQNnyZc12QLmS20wOS0';
  
  // Optional: Add other configuration values
  static const bool enableRealtime = true;
  static const bool enableDebugMode = true;
}

// Instructions to get your Supabase credentials:
// 1. Go to https://supabase.com/dashboard
// 2. Select your project (or create a new one)
// 3. Go to Settings > API
// 4. Copy the "Project URL" and paste it as supabaseUrl
// 5. Copy the "anon public" key and paste it as supabaseAnonKey
// 6. Run the SQL schema from supabase_schema.sql in your Supabase SQL Editor