-- Drop existing policies
DROP POLICY IF EXISTS "Tenant isolation for befaq_subjects" ON public.befaq_subjects;
DROP POLICY IF EXISTS "Tenant isolation for befaq_results" ON public.befaq_results;

-- Enable RLS
ALTER TABLE public.befaq_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.befaq_results ENABLE ROW LEVEL SECURITY;

-- Create explicit policies for befaq_subjects
CREATE POLICY "befaq_subjects_select" ON public.befaq_subjects
  FOR SELECT USING (
    public.is_super_admin() OR 
    EXISTS (
      SELECT 1 FROM public.befaq_exams e 
      WHERE e.id = befaq_subjects.exam_id 
      AND e.institution_id = public.get_my_institution_id()
    )
  );

CREATE POLICY "befaq_subjects_insert" ON public.befaq_subjects
  FOR INSERT WITH CHECK (
    public.is_super_admin() OR 
    EXISTS (
      SELECT 1 FROM public.befaq_exams e 
      WHERE e.id = exam_id 
      AND e.institution_id = public.get_my_institution_id()
    )
  );

CREATE POLICY "befaq_subjects_update" ON public.befaq_subjects
  FOR UPDATE USING (
    public.is_super_admin() OR 
    EXISTS (
      SELECT 1 FROM public.befaq_exams e 
      WHERE e.id = befaq_subjects.exam_id 
      AND e.institution_id = public.get_my_institution_id()
    )
  );

CREATE POLICY "befaq_subjects_delete" ON public.befaq_subjects
  FOR DELETE USING (
    public.is_super_admin() OR 
    EXISTS (
      SELECT 1 FROM public.befaq_exams e 
      WHERE e.id = befaq_subjects.exam_id 
      AND e.institution_id = public.get_my_institution_id()
    )
  );

-- Create explicit policies for befaq_results
CREATE POLICY "befaq_results_select" ON public.befaq_results
  FOR SELECT USING (
    public.is_super_admin() OR 
    EXISTS (
      SELECT 1 FROM public.befaq_exams e 
      WHERE e.id = befaq_results.exam_id 
      AND e.institution_id = public.get_my_institution_id()
    )
  );

CREATE POLICY "befaq_results_insert" ON public.befaq_results
  FOR INSERT WITH CHECK (
    public.is_super_admin() OR 
    EXISTS (
      SELECT 1 FROM public.befaq_exams e 
      WHERE e.id = exam_id 
      AND e.institution_id = public.get_my_institution_id()
    )
  );

CREATE POLICY "befaq_results_update" ON public.befaq_results
  FOR UPDATE USING (
    public.is_super_admin() OR 
    EXISTS (
      SELECT 1 FROM public.befaq_exams e 
      WHERE e.id = befaq_results.exam_id 
      AND e.institution_id = public.get_my_institution_id()
    )
  );

CREATE POLICY "befaq_results_delete" ON public.befaq_results
  FOR DELETE USING (
    public.is_super_admin() OR 
    EXISTS (
      SELECT 1 FROM public.befaq_exams e 
      WHERE e.id = befaq_results.exam_id 
      AND e.institution_id = public.get_my_institution_id()
    )
  );

NOTIFY pgrst, 'reload config';
