-- Drop existing tables if they exist to start fresh
DROP TABLE IF EXISTS public.bookmarked_lessons CASCADE;
DROP TABLE IF EXISTS public.bookmarked_courses CASCADE;

-- Bookmarked Courses table
CREATE TABLE public.bookmarked_courses (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL,
    course_id   UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, course_id)
);
CREATE INDEX idx_bc_user ON public.bookmarked_courses(user_id);

-- Bookmarked Lessons table
CREATE TABLE public.bookmarked_lessons (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL,
    lesson_id   UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    course_id   UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    chapter_id  UUID NOT NULL REFERENCES public.chapters(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, lesson_id)
);
CREATE INDEX idx_bl_user ON public.bookmarked_lessons(user_id);