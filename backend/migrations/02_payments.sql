-- ⚠️ This script creates the necessary tables for Chapa payment integration

-- 1. Transactions Table
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- The ID of the user making the purchase (optional/text if no auth yet)
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    tx_ref TEXT NOT NULL UNIQUE,
    amount NUMERIC(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, success, failed
    checkout_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. User Courses Table (to track unlocked courses)
CREATE TABLE public.user_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, course_id)
);

-- Add index on tx_ref for fast lookups
CREATE INDEX idx_transactions_tx_ref ON public.transactions(tx_ref);
