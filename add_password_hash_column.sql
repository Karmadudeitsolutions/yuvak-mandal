-- Migration to add password_hash column to existing users table
-- Run this SQL in your Supabase SQL Editor if you already have a users table

-- Add password_hash column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Update the column to be NOT NULL (optional, only if you want to enforce it)
-- Note: You'll need to add default values for existing users first
-- ALTER TABLE public.users 
-- ALTER COLUMN password_hash SET NOT NULL;

-- Optional: Add index for better performance on password lookups
CREATE INDEX IF NOT EXISTS idx_users_password_hash ON public.users(password_hash);

-- Add comment for documentation
COMMENT ON COLUMN public.users.password_hash IS 'SHA-256 hashed password for custom authentication';

-- Example of how to update existing users with a default password hash
-- (You should replace this with actual user passwords)
-- UPDATE public.users 
-- SET password_hash = 'your_default_hashed_password_here' 
-- WHERE password_hash IS NULL;

-- Verify the column was added successfully
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;
