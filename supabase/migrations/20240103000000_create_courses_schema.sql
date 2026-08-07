-- =============================================
-- CATEGORIES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    course_count INTEGER DEFAULT 0,
    color_hex TEXT DEFAULT '#1565C0',
    icon TEXT DEFAULT 'school',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default categories
INSERT INTO public.categories (name, description, course_count, color_hex, icon) VALUES
    ('Grade 12', 'Ethiopian Grade 12 subjects', 120, '#1565C0', 'school'),
    ('Freshman', 'University freshman courses', 150, '#6A1B9A', 'auto_stories'),
    ('TVET', 'Technical and Vocational Training', 60, '#E65100', 'build')
ON CONFLICT DO NOTHING;

-- =============================================
-- COURSES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    instructor_name TEXT NOT NULL,
    thumbnail_url TEXT,
    total_chapters INTEGER DEFAULT 0,
    price NUMERIC(10,2) DEFAULT 0,
    is_free BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for courses
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view courses" ON public.courses FOR SELECT USING (true);
CREATE POLICY "Admins can manage courses" ON public.courses FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- =============================================
-- CHAPTERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.chapters (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    chapter_number INTEGER NOT NULL,
    duration_seconds INTEGER DEFAULT 0,
    video_url TEXT,
    is_free BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view chapters" ON public.chapters FOR SELECT USING (true);
CREATE POLICY "Admins can manage chapters" ON public.chapters FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- =============================================
-- ENROLLMENTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    progress_percent INTEGER DEFAULT 0,
    last_chapter_id UUID REFERENCES public.chapters(id) ON DELETE SET NULL,
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, course_id)
);

ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students view own enrollments" ON public.enrollments
    FOR SELECT USING (auth.uid() = student_id);
CREATE POLICY "Students enroll themselves" ON public.enrollments
    FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "Students update own enrollment" ON public.enrollments
    FOR UPDATE USING (auth.uid() = student_id);

-- =============================================
-- CHAPTER PROGRESS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.chapter_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    chapter_id UUID REFERENCES public.chapters(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    is_completed BOOLEAN DEFAULT false,
    watched_seconds INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, chapter_id)
);

ALTER TABLE public.chapter_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students manage own chapter progress" ON public.chapter_progress
    FOR ALL USING (auth.uid() = student_id);

-- =============================================
-- CHAPTER UNLOCKS (paid chapters)
-- =============================================
CREATE TABLE IF NOT EXISTS public.chapter_unlocks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    chapter_id UUID REFERENCES public.chapters(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    payment_reference TEXT,
    UNIQUE(student_id, chapter_id)
);

ALTER TABLE public.chapter_unlocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students view own unlocks" ON public.chapter_unlocks
    FOR SELECT USING (auth.uid() = student_id);
CREATE POLICY "Students insert own unlocks" ON public.chapter_unlocks
    FOR INSERT WITH CHECK (auth.uid() = student_id);
