-- ============================================================
-- FASTER (First-Aid Service Team Emergency Response)
-- Supabase PostgreSQL Database Setup & Repair Migration
-- ============================================================
-- Run this SQL in the Supabase SQL Editor:
-- Dashboard -> Project -> SQL Editor -> New Query -> Run
-- ============================================================

-- 1. Students Table (fast_stud_info)
CREATE TABLE IF NOT EXISTS public.fast_stud_info (
    stud_id BIGINT PRIMARY KEY,
    stud_fn VARCHAR(50) NOT NULL,
    stud_mi VARCHAR(10) DEFAULT 'N/A',
    stud_ln VARCHAR(50) NOT NULL,
    stud_user VARCHAR(50) UNIQUE NOT NULL,
    stud_password VARCHAR(100) NOT NULL,
    stud_program VARCHAR(50) NOT NULL,
    stud_yrlevel VARCHAR(20) NOT NULL,
    stud_section VARCHAR(20) NOT NULL,
    stud_phoneno VARCHAR(20) NOT NULL,
    user_role VARCHAR(20) DEFAULT 'STUDENT',
    is_distress BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure user_role and is_distress exist if table was already created
ALTER TABLE public.fast_stud_info ADD COLUMN IF NOT EXISTS user_role VARCHAR(20) DEFAULT 'STUDENT';
ALTER TABLE public.fast_stud_info ADD COLUMN IF NOT EXISTS is_distress BOOLEAN DEFAULT FALSE;

-- 2. Distress Records Table (fast_stud_record)
CREATE TABLE IF NOT EXISTS public.fast_stud_record (
    id BIGSERIAL PRIMARY KEY,
    stud_id BIGINT NOT NULL,
    stud_name VARCHAR(120) NOT NULL,
    stud_program VARCHAR(50),
    stud_yrlevel VARCHAR(20),
    stud_section VARCHAR(20),
    user_role TEXT,
    stud_status VARCHAR(50) DEFAULT 'ACTIVE DISTRESS',
    room_name VARCHAR(100),
    floor INT DEFAULT 0,
    stud_reqtime TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure all columns exist on fast_stud_record if previously created
ALTER TABLE public.fast_stud_record ADD COLUMN IF NOT EXISTS stud_status VARCHAR(50) DEFAULT 'ACTIVE DISTRESS';
ALTER TABLE public.fast_stud_record ADD COLUMN IF NOT EXISTS user_role TEXT;
ALTER TABLE public.fast_stud_record ADD COLUMN IF NOT EXISTS room_name VARCHAR(100);
ALTER TABLE public.fast_stud_record ADD COLUMN IF NOT EXISTS floor INT DEFAULT 0;
ALTER TABLE public.fast_stud_record ADD COLUMN IF NOT EXISTS stud_reqtime TIMESTAMPTZ DEFAULT NOW();

-- 3. Emergency Request Log (user_request)
CREATE TABLE IF NOT EXISTS public.user_request (
    id BIGSERIAL PRIMARY KEY,
    stud_id BIGINT,
    stud_name VARCHAR(120) NOT NULL,
    stud_program VARCHAR(50),
    user_reqtime TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_request ADD COLUMN IF NOT EXISTS user_reqtime TIMESTAMPTZ DEFAULT NOW();

-- 4. Safely drop any legacy broken triggers referencing old schema
DROP TRIGGER IF EXISTS trigger_sync_distress ON public.fast_stud_info;
DROP TRIGGER IF EXISTS trigger_auto_record ON public.fast_stud_info;
DROP FUNCTION IF EXISTS public.fn_sync_distress_record();

-- 5. Enable Row Level Security (RLS) & Grant Access for Anon role
ALTER TABLE public.fast_stud_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fast_stud_record ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_request ENABLE ROW LEVEL SECURITY;

-- Allow anon read/write policies
DO $$
BEGIN
    DROP POLICY IF EXISTS "Anon public full access fast_stud_info" ON public.fast_stud_info;
    CREATE POLICY "Anon public full access fast_stud_info" ON public.fast_stud_info FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Anon public full access fast_stud_record" ON public.fast_stud_record;
    CREATE POLICY "Anon public full access fast_stud_record" ON public.fast_stud_record FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Anon public full access user_request" ON public.user_request;
    CREATE POLICY "Anon public full access user_request" ON public.user_request FOR ALL USING (true) WITH CHECK (true);
END
$$;

-- 6. Enable Realtime Replication for distress sync
ALTER PUBLICATION supabase_realtime ADD TABLE public.fast_stud_info;
ALTER PUBLICATION supabase_realtime ADD TABLE public.fast_stud_record;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_request;
