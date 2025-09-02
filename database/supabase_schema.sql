-- Supabase Database Schema for Mandal Loan System
-- Run these commands in your Supabase SQL Editor

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Create users table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'Member' CHECK (role IN ('Admin', 'Manager', 'Member')),
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create groups table
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create group_members table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'Member' CHECK (role IN ('Admin', 'Manager', 'Member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- Create contributions table
CREATE TABLE IF NOT EXISTS public.contributions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    description TEXT,
    contribution_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create loan_requests table
CREATE TABLE IF NOT EXISTS public.loan_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    purpose TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    interest_rate DECIMAL(5,2) DEFAULT 0.00,
    duration_months INTEGER DEFAULT 12,
    approved_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    approved_at TIMESTAMP WITH TIME ZONE,
    due_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create repayments table
CREATE TABLE IF NOT EXISTS public.repayments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    loan_id UUID REFERENCES public.loan_requests(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method TEXT DEFAULT 'cash',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_group_id ON public.contributions(group_id);
CREATE INDEX IF NOT EXISTS idx_contributions_user_id ON public.contributions(user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_date ON public.contributions(contribution_date);
CREATE INDEX IF NOT EXISTS idx_loan_requests_group_id ON public.loan_requests(group_id);
CREATE INDEX IF NOT EXISTS idx_loan_requests_user_id ON public.loan_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_loan_requests_status ON public.loan_requests(status);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON public.repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_repayments_user_id ON public.repayments(user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_groups_updated_at BEFORE UPDATE ON public.groups FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_contributions_updated_at BEFORE UPDATE ON public.contributions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_loan_requests_updated_at BEFORE UPDATE ON public.loan_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_repayments_updated_at BEFORE UPDATE ON public.repayments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

CREATE POLICY "Admins can update user roles" ON public.users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

-- Groups table policies
CREATE POLICY "Users can view groups they belong to" ON public.groups
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_id = id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Group admins can update groups" ON public.groups
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_id = id AND user_id = auth.uid() AND role IN ('Admin', 'Manager')
        )
    );

CREATE POLICY "Authenticated users can create groups" ON public.groups
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Group members table policies
CREATE POLICY "Users can view group memberships" ON public.group_members
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM public.group_members gm 
            WHERE gm.group_id = group_id AND gm.user_id = auth.uid() AND gm.role IN ('Admin', 'Manager')
        )
    );

CREATE POLICY "Group admins can manage members" ON public.group_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_id = group_members.group_id AND user_id = auth.uid() AND role IN ('Admin', 'Manager')
        )
    );

-- Contributions table policies
CREATE POLICY "Users can view contributions in their groups" ON public.contributions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_id = contributions.group_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create contributions in their groups" ON public.contributions
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_id = contributions.group_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own contributions" ON public.contributions
    FOR UPDATE USING (user_id = auth.uid());

-- Loan requests table policies
CREATE POLICY "Users can view loan requests in their groups" ON public.loan_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_id = loan_requests.group_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create loan requests in their groups" ON public.loan_requests
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_id = loan_requests.group_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Group admins can update loan requests" ON public.loan_requests
    FOR UPDATE USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_id = loan_requests.group_id AND user_id = auth.uid() AND role IN ('Admin', 'Manager')
        )
    );

-- Repayments table policies
CREATE POLICY "Users can view repayments for their loans" ON public.repayments
    FOR SELECT USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.loan_requests lr
            JOIN public.group_members gm ON lr.group_id = gm.group_id
            WHERE lr.id = loan_id AND gm.user_id = auth.uid() AND gm.role IN ('Admin', 'Manager')
        )
    );

CREATE POLICY "Users can create repayments for their loans" ON public.repayments
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.loan_requests 
            WHERE id = loan_id AND user_id = auth.uid()
        )
    );

-- Create a function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, name, email, phone, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', ''),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'Member')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create some useful views
CREATE OR REPLACE VIEW public.group_statistics AS
SELECT 
    g.id,
    g.name,
    COUNT(DISTINCT gm.user_id) as member_count,
    COALESCE(SUM(c.amount), 0) as total_contributions,
    COALESCE(SUM(CASE WHEN lr.status = 'approved' THEN lr.amount ELSE 0 END), 0) as total_active_loans,
    COALESCE(SUM(r.amount), 0) as total_repayments
FROM public.groups g
LEFT JOIN public.group_members gm ON g.id = gm.group_id
LEFT JOIN public.contributions c ON g.id = c.group_id
LEFT JOIN public.loan_requests lr ON g.id = lr.group_id
LEFT JOIN public.repayments r ON lr.id = r.loan_id
GROUP BY g.id, g.name;

CREATE OR REPLACE VIEW public.user_statistics AS
SELECT 
    u.id,
    u.name,
    u.email,
    COALESCE(SUM(c.amount), 0) as total_contributions,
    COALESCE(SUM(CASE WHEN lr.status = 'approved' THEN lr.amount ELSE 0 END), 0) as total_borrowed,
    COALESCE(SUM(r.amount), 0) as total_repaid,
    COALESCE(SUM(CASE WHEN lr.status = 'approved' THEN lr.amount ELSE 0 END), 0) - COALESCE(SUM(r.amount), 0) as outstanding_balance
FROM public.users u
LEFT JOIN public.contributions c ON u.id = c.user_id
LEFT JOIN public.loan_requests lr ON u.id = lr.user_id
LEFT JOIN public.repayments r ON u.id = r.user_id
GROUP BY u.id, u.name, u.email;