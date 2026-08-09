-- EthioClass Supabase Database Schema
-- Run this in your Supabase SQL Editor

-- ─────────────────────────────────────────────
-- PROFILES (extends Supabase auth.users)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   TEXT,
  avatar_url  TEXT,
  role        TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin', 'instructor')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', 'student');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ─────────────────────────────────────────────
-- COURSES
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS courses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  description     TEXT,
  category        TEXT NOT NULL,
  instructor_id   UUID REFERENCES profiles(id) ON DELETE SET NULL,
  thumbnail_key   TEXT,  -- Cloudflare R2 object key (e.g. "images/uuid.png")
  is_published    BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- COURSE MODULES (Video Lessons)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS course_modules (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id   UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  video_key   TEXT,  -- Cloudflare R2 object key (e.g. "videos/uuid.mp4")
  pdf_key     TEXT,  -- Cloudflare R2 object key (e.g. "documents/uuid.pdf")
  sort_order  INTEGER NOT NULL DEFAULT 1,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- ENROLLMENTS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS enrollments (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id    UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  progress     INTEGER DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  enrolled_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

-- ─────────────────────────────────────────────
-- BOOKMARKS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookmarks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id   UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

-- ─────────────────────────────────────────────
-- ROW LEVEL SECURITY (RLS)
-- ─────────────────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

-- Profiles: users can view all, but only update their own
CREATE POLICY "Public profiles are viewable" ON profiles FOR SELECT USING (TRUE);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Courses: anyone authenticated can view published courses
CREATE POLICY "Published courses viewable" ON courses FOR SELECT USING (is_published = TRUE OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));
CREATE POLICY "Admins can insert courses" ON courses FOR INSERT WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));
CREATE POLICY "Admins can update courses" ON courses FOR UPDATE USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Modules: viewable if enrolled or admin
CREATE POLICY "Modules viewable for enrolled users" ON course_modules FOR SELECT USING (
  auth.uid() IN (SELECT user_id FROM enrollments WHERE course_id = course_modules.course_id)
  OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
);
CREATE POLICY "Admins can insert modules" ON course_modules FOR INSERT WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Enrollments: users see their own
CREATE POLICY "Users see own enrollments" ON enrollments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can enroll" ON enrollments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON enrollments FOR UPDATE USING (auth.uid() = user_id);

-- Bookmarks: users manage their own
CREATE POLICY "Users manage own bookmarks" ON bookmarks FOR ALL USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- SEED: Sample Admin User role
-- After running this, set a user's role to 'admin' via:
-- UPDATE profiles SET role = 'admin' WHERE id = '<your-user-uuid>';
-- ─────────────────────────────────────────────
