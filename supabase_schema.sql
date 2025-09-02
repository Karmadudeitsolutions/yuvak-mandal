-- Supabase Database Schema for Mandal App
-- Run this SQL in your Supabase SQL Editor

-- Create users table (extends Supabase Auth)
-- This table stores additional user profile information
-- The id field references auth.users.id (UUID)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'Member',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create groups table
CREATE TABLE IF NOT EXISTS groups (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    monthly_contribution DECIMAL(10,2) NOT NULL,
    admin_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create group_members table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS group_members (
    id BIGSERIAL PRIMARY KEY,
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- Create contributions table
CREATE TABLE IF NOT EXISTS contributions (
    id BIGSERIAL PRIMARY KEY,
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    paid_date DATE,
    status VARCHAR(20) DEFAULT 'Pending',
    period VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create loan_requests table
CREATE TABLE IF NOT EXISTS loan_requests (
    id BIGSERIAL PRIMARY KEY,
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    purpose TEXT,
    status VARCHAR(20) DEFAULT 'Pending',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    due_date DATE,
    interest_rate DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create repayments table
CREATE TABLE IF NOT EXISTS repayments (
    id BIGSERIAL PRIMARY KEY,
    loan_request_id BIGINT REFERENCES loan_requests(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_group_id ON contributions(group_id);
CREATE INDEX IF NOT EXISTS idx_contributions_user_id ON contributions(user_id);
CREATE INDEX IF NOT EXISTS idx_loan_requests_group_id ON loan_requests(group_id);
CREATE INDEX IF NOT EXISTS idx_loan_requests_user_id ON loan_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_request_id ON repayments(loan_request_id);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE repayments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (basic policies - you can customize based on your needs)

-- Users can read their own data and admins can read all
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (true); -- For now, allow all reads - customize as needed

-- Users can update their own data
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (true); -- For now, allow all updates - customize as needed

-- Allow inserts for registration
CREATE POLICY "Allow user registration" ON users
    FOR INSERT WITH CHECK (true);

-- Groups policies
CREATE POLICY "Users can view groups they belong to" ON groups
    FOR SELECT USING (true); -- For now, allow all reads - customize as needed

CREATE POLICY "Admins can manage groups" ON groups
    FOR ALL USING (true); -- For now, allow all operations - customize as needed

-- Group members policies
CREATE POLICY "Users can view group memberships" ON group_members
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage group memberships" ON group_members
    FOR ALL USING (true);

-- Contributions policies
CREATE POLICY "Users can view contributions" ON contributions
    FOR SELECT USING (true);

CREATE POLICY "Users can manage contributions" ON contributions
    FOR ALL USING (true);

-- Loan requests policies
CREATE POLICY "Users can view loan requests" ON loan_requests
    FOR SELECT USING (true);

CREATE POLICY "Users can manage loan requests" ON loan_requests
    FOR ALL USING (true);

-- Repayments policies
CREATE POLICY "Users can view repayments" ON repayments
    FOR SELECT USING (true);

CREATE POLICY "Users can manage repayments" ON repayments
    FOR ALL USING (true);

-- Note: To create an admin user, you'll need to:
-- 1. Register through the app or Supabase Auth
-- 2. Then manually update the role in the users table:
-- UPDATE users SET role = 'Admin' WHERE email = 'your-admin-email@example.com';

-- Create a function to automatically create user profile when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, name, email, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'New User'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    'Member'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();