-- URGENT: Fix Database Constraints for Custom Authentication
-- Run this IMMEDIATELY in your Supabase SQL Editor to fix the registration error

-- Step 1: Check current constraints (for debugging)
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='users'
    AND tc.table_schema='public';

-- Step 2: Drop the foreign key constraint that's causing the error
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_id_fkey;

-- Step 3: Also drop any other auth-related constraints
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_auth_id_fkey;

ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_user_id_fkey;

-- Step 4: Add password_hash column if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Step 5: DISABLE Row Level Security temporarily for testing
-- This is the most likely cause of insert failures
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Step 6: Create email index for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- Step 7: Make email column unique if it isn't already
ALTER TABLE public.users 
ADD CONSTRAINT users_email_unique UNIQUE (email);

-- Step 8: Verify the table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 9: Check if RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Step 10: Test insert (optional - remove this after testing)
-- INSERT INTO public.users (id, name, email, phone, password_hash, role, created_at, updated_at)
-- VALUES (
--     gen_random_uuid(),
--     'Test User',
--     'test@example.com',
--     '1234567890',
--     'test_hash',
--     'Member',
--     NOW(),
--     NOW()
-- );

-- Step 11: If you want to re-enable RLS later with custom policies, use:
-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- 
-- Then create custom policies like:
-- CREATE POLICY "Allow public insert" ON public.users FOR INSERT WITH CHECK (true);
-- CREATE POLICY "Allow public select" ON public.users FOR SELECT USING (true);
-- CREATE POLICY "Allow public update" ON public.users FOR UPDATE USING (true);
-- CREATE POLICY "Allow public delete" ON public.users FOR DELETE USING (true);

COMMENT ON TABLE public.users IS 'Custom users table with password authentication - RLS disabled for custom auth';
COMMENT ON COLUMN public.users.password_hash IS 'SHA-256 hashed password for custom authentication';