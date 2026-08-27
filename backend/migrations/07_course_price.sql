-- Add price column to courses table
-- Run this in Supabase SQL editor
ALTER TABLE public.courses
  ADD COLUMN IF NOT EXISTS price INTEGER NOT NULL DEFAULT 249;

-- Update existing courses to have 249 Birr as default price
UPDATE public.courses SET price = 249 WHERE price IS NULL OR price = 0;
