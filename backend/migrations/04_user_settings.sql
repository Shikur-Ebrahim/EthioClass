-- User Settings Table
DROP TABLE IF EXISTS public.user_settings;

CREATE TABLE public.user_settings (
    user_id VARCHAR(255) PRIMARY KEY,
    theme VARCHAR(20) DEFAULT 'system',
    download_quality VARCHAR(20) DEFAULT '720p',
    push_notifications BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    language VARCHAR(10) DEFAULT 'en',
    updated_at TIMESTAMPTZ DEFAULT now()
);
