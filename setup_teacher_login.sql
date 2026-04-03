-- Add pin and permissions columns to teachers table
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS pin TEXT;
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{"can_manage_attendance": false, "can_manage_results": false, "allowed_classes": []}'::jsonb;

-- Update RLS policies for teachers table to allow teachers to read their own data
DROP POLICY IF EXISTS "Teachers can view their own data" ON public.teachers;
CREATE POLICY "Teachers can view their own data" ON public.teachers
  FOR SELECT USING (
    id::text = current_setting('request.jwt.claims', true)::jsonb->>'sub'
    OR
    institution_id = public.get_my_institution_id()
    OR
    public.is_super_admin()
  );

-- Allow teachers to update their own pin
DROP POLICY IF EXISTS "Teachers can update their own pin" ON public.teachers;
CREATE POLICY "Teachers can update their own pin" ON public.teachers
  FOR UPDATE USING (
    id::text = current_setting('request.jwt.claims', true)::jsonb->>'sub'
  ) WITH CHECK (
    id::text = current_setting('request.jwt.claims', true)::jsonb->>'sub'
  );

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
