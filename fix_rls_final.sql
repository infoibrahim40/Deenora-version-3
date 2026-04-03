-- 1. Update check_is_super_admin function to include hardcoded super admin emails
CREATE OR REPLACE FUNCTION public.check_is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  ) OR (auth.jwt()->>'email' IN ('kmibrahim@gmail.com', 'thedevomix@gmail.com'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update is_super_admin function to use check_is_super_admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.check_is_super_admin();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Drop existing policy for befaq_exams
DROP POLICY IF EXISTS "Tenant isolation for befaq_exams" ON public.befaq_exams;

-- 4. Create explicit policies for befaq_exams
CREATE POLICY "befaq_exams_select" ON public.befaq_exams
  FOR SELECT USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

CREATE POLICY "befaq_exams_insert" ON public.befaq_exams
  FOR INSERT WITH CHECK (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

CREATE POLICY "befaq_exams_update" ON public.befaq_exams
  FOR UPDATE USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

CREATE POLICY "befaq_exams_delete" ON public.befaq_exams
  FOR DELETE USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

-- 5. Drop existing policy for qawmi_result_configs
DROP POLICY IF EXISTS "Tenant isolation for qawmi_result_configs" ON public.qawmi_result_configs;

-- 6. Create explicit policies for qawmi_result_configs
CREATE POLICY "qawmi_result_configs_select" ON public.qawmi_result_configs
  FOR SELECT USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

CREATE POLICY "qawmi_result_configs_insert" ON public.qawmi_result_configs
  FOR INSERT WITH CHECK (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

CREATE POLICY "qawmi_result_configs_update" ON public.qawmi_result_configs
  FOR UPDATE USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

CREATE POLICY "qawmi_result_configs_delete" ON public.qawmi_result_configs
  FOR DELETE USING (
    public.is_super_admin() OR 
    (public.get_my_institution_id() IS NOT NULL AND institution_id = public.get_my_institution_id())
  );

-- 7. Force schema cache reload
NOTIFY pgrst, 'reload config';
