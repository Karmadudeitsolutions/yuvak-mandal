-- Database Update Script for Custom Authentication
-- Run this in your Supabase SQL Editor

-- Step 1: Add password_hash column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Step 2: Drop the foreign key constraint to auth.users (if it exists)
-- This allows us to use custom UUIDs instead of auth.users IDs
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_id_fkey;

-- Step 3: Make sure the id column is properly configured as UUID primary key
-- (This should already be the case, but just to be sure)
ALTER TABLE public.users 
ALTER COLUMN id TYPE UUID USING id::UUID;

-- Step 4: Update the table comment to reflect the new structure
COMMENT ON TABLE public.users IS 'Custom users table with password authentication';
COMMENT ON COLUMN public.users.password_hash IS 'SHA-256 hashed password';

-- Step 5: Create an index on email for faster lookups during login
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- Step 6: Ensure RLS (Row Level Security) policies are appropriate
-- You may need to adjust these based on your security requirements

-- Example: Allow users to read their own data
-- CREATE POLICY "Users can view own profile" ON public.users
--   FOR SELECT USING (auth.uid() = id);

-- Example: Allow users to update their own data
-- CREATE POLICY "Users can update own profile" ON public.users
--   FOR UPDATE USING (auth.uid() = id);

-- Note: Since we're not using Supabase Auth anymore, you might want to
-- disable RLS or create custom policies based on your application logic
-- ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Verification query - run this to check the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;