-- Fix RLS policies for calendar_events table

-- Fix check constraint to allow 'closed'
DO $$
DECLARE
    v_constraint_name text;
BEGIN
    SELECT conname INTO v_constraint_name
    FROM pg_constraint
    WHERE conrelid = 'public.calendar_events'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) LIKE '%event_type%'
    LIMIT 1;

    IF v_constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE public.calendar_events DROP CONSTRAINT ' || v_constraint_name;
    END IF;
END $$;

ALTER TABLE public.calendar_events ADD CONSTRAINT calendar_events_event_type_check CHECK (event_type IN ('islamic', 'madrasah', 'holiday', 'closed'));

-- Drop existing policies
DROP POLICY IF EXISTS "Institutions can view their own calendar events" ON public.calendar_events;
DROP POLICY IF EXISTS "Admins can manage their own calendar events" ON public.calendar_events;

-- Create explicit policies
CREATE POLICY "calendar_events_select" ON public.calendar_events
  FOR SELECT USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

CREATE POLICY "calendar_events_insert" ON public.calendar_events
  FOR INSERT WITH CHECK (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id() AND EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'madrasah_admin'
    ))
  );

CREATE POLICY "calendar_events_update" ON public.calendar_events
  FOR UPDATE USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id() AND EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'madrasah_admin'
    ))
  );

CREATE POLICY "calendar_events_delete" ON public.calendar_events
  FOR DELETE USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id() AND EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'madrasah_admin'
    ))
  );

-- Force schema cache reload
NOTIFY pgrst, 'reload config';
