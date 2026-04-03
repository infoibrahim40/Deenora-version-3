-- Drop existing policy
DROP POLICY IF EXISTS "Tenant isolation for befaq_exams" ON public.befaq_exams;

-- Create explicit policies
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

-- Also fix qawmi_result_configs
DROP POLICY IF EXISTS "Tenant isolation for qawmi_result_configs" ON public.qawmi_result_configs;

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

NOTIFY pgrst, 'reload config';
