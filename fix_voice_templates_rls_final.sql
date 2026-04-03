-- Final fix for voice_templates RLS to allow Super Admins full access
-- This ensures Super Admins can assign voices to any institution without RLS violations

-- 1. Enable RLS
ALTER TABLE public.voice_templates ENABLE ROW LEVEL SECURITY;

-- 2. Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Institutions can view their own voice templates" ON public.voice_templates;
DROP POLICY IF EXISTS "Institutions can insert their own voice templates" ON public.voice_templates;
DROP POLICY IF EXISTS "Institutions can update their own voice templates" ON public.voice_templates;
DROP POLICY IF EXISTS "Institutions can delete their own voice templates" ON public.voice_templates;
DROP POLICY IF EXISTS "Super Admins can view all voice templates" ON public.voice_templates;
DROP POLICY IF EXISTS "Super Admins can insert all voice templates" ON public.voice_templates;
DROP POLICY IF EXISTS "Super Admins can update all voice templates" ON public.voice_templates;
DROP POLICY IF EXISTS "Super Admins can delete all voice templates" ON public.voice_templates;

-- 3. Create SELECT policy (Permissive)
CREATE POLICY "voice_templates_select_policy" ON public.voice_templates
    FOR SELECT USING (
        public.is_super_admin() 
        OR institution_id = public.get_my_institution_id()
    );

-- 4. Create INSERT policy (Permissive)
-- This is the one causing the "new row violates row-level security policy" error
CREATE POLICY "voice_templates_insert_policy" ON public.voice_templates
    FOR INSERT WITH CHECK (
        public.is_super_admin() 
        OR institution_id = public.get_my_institution_id()
    );

-- 5. Create UPDATE policy (Permissive)
CREATE POLICY "voice_templates_update_policy" ON public.voice_templates
    FOR UPDATE USING (
        public.is_super_admin() 
        OR institution_id = public.get_my_institution_id()
    );

-- 6. Create DELETE policy (Permissive)
CREATE POLICY "voice_templates_delete_policy" ON public.voice_templates
    FOR DELETE USING (
        public.is_super_admin() 
        OR institution_id = public.get_my_institution_id()
    );

-- 7. Ensure the is_super_admin function is robust
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- Use a direct query to avoid any potential recursion or path issues
  -- Also handle the case where auth.uid() might be null
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Ensure get_my_institution_id is robust
CREATE OR REPLACE FUNCTION public.get_my_institution_id()
RETURNS UUID AS $$
DECLARE
  v_inst_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT institution_id INTO v_inst_id
  FROM public.profiles
  WHERE id = auth.uid();
  
  RETURN v_inst_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
