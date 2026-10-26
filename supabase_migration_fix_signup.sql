-- ============================================================================
-- FASTER APP DATABASE MIGRATION: Fix Sign-Up Failure (Error 42703)
-- Execute this script in:
-- Supabase Dashboard -> SQL Editor (https://supabase.com/dashboard/project/ofdxpepncrzrfzarvjtb/sql/new)
-- ============================================================================

-- STEP 1: Add the missing 'stud_status' column to fast_stud_info
-- Root Cause: A trigger on fast_stud_info references NEW.stud_status, but the table
-- lacked this column, causing PostgreSQL to abort sign-up inserts with error 42703:
-- "record 'new' has no field 'stud_status'".
ALTER TABLE public.fast_stud_info 
ADD COLUMN IF NOT EXISTS stud_status text DEFAULT 'ACTIVE';

-- STEP 2: Inspect existing triggers on fast_stud_info (diagnostic review)
SELECT 
    trigger_name, 
    action_timing, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'fast_stud_info';

-- STEP 3: Ensure Row Level Security allows authenticated & public app operations
ALTER TABLE public.fast_stud_info ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all access to fast_stud_info" ON public.fast_stud_info;
CREATE POLICY "Allow all access to fast_stud_info" 
ON public.fast_stud_info 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Ensure RLS on fast_stud_record as well
ALTER TABLE public.fast_stud_record ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all access to fast_stud_record" ON public.fast_stud_record;
CREATE POLICY "Allow all access to fast_stud_record" 
ON public.fast_stud_record 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Ensure RLS on user_request as well
ALTER TABLE public.user_request ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all access to user_request" ON public.user_request;
CREATE POLICY "Allow all access to user_request" 
ON public.user_request 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- STEP 4: Tell PostgREST to immediately refresh its schema cache
NOTIFY pgrst, 'reload schema';
