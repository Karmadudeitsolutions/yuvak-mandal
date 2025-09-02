-- Test Database Fix - Run this AFTER running fix_database_constraints.sql
-- This will verify that the database is ready for custom authentication

-- Test 1: Check if foreign key constraints are removed
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

-- Test 2: Verify table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test 3: Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Test 4: Try a test insert (this should work now)
INSERT INTO public.users (id, name, email, phone, password_hash, role, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'Database Test User',
    'dbtest@example.com',
    '9876543210',
    'test_password_hash_12345',
    'Member',
    NOW(),
    NOW()
);

-- Test 5: Verify the insert worked
SELECT id, name, email, phone, role, created_at 
FROM public.users 
WHERE email = 'dbtest@example.com';

-- Test 6: Clean up test data
DELETE FROM public.users WHERE email = 'dbtest@example.com';

-- If all tests pass, your database is ready for custom authentication!