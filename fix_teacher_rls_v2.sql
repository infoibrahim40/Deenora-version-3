
-- 1. Unify and fix institution ID helper functions
CREATE OR REPLACE FUNCTION public.get_my_institution_id()
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT institution_id FROM public.profiles 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Alias for backward compatibility if needed
CREATE OR REPLACE FUNCTION public.get_authenticated_institution_id()
RETURNS UUID AS $$
BEGIN
  RETURN public.get_my_institution_id();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 2. Robust super admin check
CREATE OR REPLACE FUNCTION public.check_is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  ) OR (auth.jwt()->>'email' IN ('kmibrahim@gmail.com', 'thedevomix@gmail.com'));
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Alias for backward compatibility
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.check_is_super_admin();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 3. Ensure RLS is enabled on all core tables
ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_marks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voices ENABLE ROW LEVEL SECURITY;

-- 4. Re-apply core isolation policies using the unified function
-- We use DO block to drop and recreate policies to avoid "already exists" errors

DO $$ 
DECLARE 
    t text;
    p text;
BEGIN
    -- Drop existing isolation policies to re-apply them cleanly
    FOR t, p IN 
        SELECT tablename, policyname FROM pg_policies 
        WHERE schemaname = 'public' 
        AND (policyname LIKE '%isolation%' OR policyname LIKE '%access%' OR policyname LIKE '%view%' OR policyname LIKE '%insert%' OR policyname LIKE '%update%' OR policyname LIKE '%delete%')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', p, t);
    END LOOP;
END $$;

-- PROFILES
CREATE POLICY "profiles_institution_access" ON public.profiles FOR SELECT USING (id = auth.uid() OR (institution_id IS NOT NULL AND institution_id = public.get_my_institution_id()) OR public.check_is_super_admin());
CREATE POLICY "profiles_self_update" ON public.profiles FOR UPDATE USING (auth.uid() = id OR public.check_is_super_admin());

-- INSTITUTIONS
CREATE POLICY "institution_select" ON public.institutions FOR SELECT USING (id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "institution_update" ON public.institutions FOR UPDATE USING (id = public.get_my_institution_id() OR public.check_is_super_admin());

-- CLASSES
CREATE POLICY "classes_isolation" ON public.classes FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- STUDENTS
CREATE POLICY "students_isolation" ON public.students FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- TEACHERS
CREATE POLICY "teachers_isolation" ON public.teachers FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- ATTENDANCE
CREATE POLICY "attendance_isolation" ON public.attendance FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- EXAMS
CREATE POLICY "exams_isolation" ON public.exams FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- EXAM SUBJECTS
CREATE POLICY "exam_subjects_isolation" ON public.exam_subjects FOR ALL USING (
  EXISTS (SELECT 1 FROM public.exams e WHERE e.id = exam_subjects.exam_id AND (e.institution_id = public.get_my_institution_id() OR public.check_is_super_admin()))
);

-- EXAM MARKS
CREATE POLICY "exam_marks_isolation" ON public.exam_marks FOR ALL USING (
  EXISTS (SELECT 1 FROM public.exams e WHERE e.id = exam_marks.exam_id AND (e.institution_id = public.get_my_institution_id() OR public.check_is_super_admin()))
);

-- FINANCIALS
CREATE POLICY "ledger_isolation" ON public.ledger FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "fees_isolation" ON public.fees FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "fee_structures_isolation" ON public.fee_structures FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- SMS/VOICE
CREATE POLICY "sms_templates_isolation" ON public.sms_templates FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "voice_templates_isolation" ON public.voice_templates FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "voice_broadcasts_isolation" ON public.voice_broadcasts FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "voice_call_logs_isolation" ON public.voice_call_logs FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "wallets_isolation" ON public.wallets FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "wallet_transactions_isolation" ON public.wallet_transactions FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "voices_isolation" ON public.voices FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- TRANSACTIONS
CREATE POLICY "transactions_isolation" ON public.transactions FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- BEFAQ EXAMS (from fix_rls_final.sql)
CREATE POLICY "befaq_exams_isolation" ON public.befaq_exams FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());
CREATE POLICY "qawmi_result_configs_isolation" ON public.qawmi_result_configs FOR ALL USING (institution_id = public.get_my_institution_id() OR public.check_is_super_admin());

-- 5. Force schema cache reload
NOTIFY pgrst, 'reload config';
