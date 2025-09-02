-- Migration to add missing fields to groups table
-- Run this in your Supabase SQL Editor

-- Add join_code field to groups table
ALTER TABLE public.groups 
ADD COLUMN IF NOT EXISTS join_code VARCHAR(10) UNIQUE;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_groups_join_code ON public.groups(join_code);

-- Verify the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'groups' AND table_schema = 'public'
ORDER BY ordinal_position;
