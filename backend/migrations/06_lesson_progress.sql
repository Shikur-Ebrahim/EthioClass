-- 06_lesson_progress.sql
-- Track which lessons each user has completed and when they last accessed each course

CREATE TABLE IF NOT EXISTS public.lesson_progress (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID NOT NULL,
    course_id        UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    lesson_id        UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    completed        BOOLEAN NOT NULL DEFAULT false,
    last_accessed_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_at       TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS idx_lp_user_course ON public.lesson_progress(user_id, course_id);
CREATE INDEX IF NOT EXISTS idx_lp_user ON public.lesson_progress(user_id);
