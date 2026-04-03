-- Fix teacher login and data access issues
-- 1. Fix the handle_new_auth_user trigger to ignore teacher accounts
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
DECLARE
    v_full_name TEXT;
    v_institution_name TEXT;
BEGIN
    -- Skip for teacher accounts (they are handled by check_teacher_login)
    IF NEW.email LIKE '%@teacher.deenora.com' THEN
        RETURN NEW;
    END IF;

    v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email);
    v_institution_name := COALESCE(NEW.raw_user_meta_data->>'institution_name', v_full_name || '''s Institution');

    -- Only create institution and profile for non-teacher accounts (admins)
    IF NEW.email = 'kmibrahim@gmail.com' OR NEW.email = 'thedevomix@gmail.com' THEN
        INSERT INTO public.profiles (id, institution_id, full_name, role, is_active)
        VALUES (NEW.id, NULL, v_full_name, 'super_admin', true)
        ON CONFLICT ON CONSTRAINT profiles_pkey DO UPDATE SET role = 'super_admin';
    ELSE
        -- Create a new institution for the admin
        INSERT INTO public.institutions (id, name, email, is_active, is_super_admin, balance, sms_balance, institution_type)
        VALUES (NEW.id, v_institution_name, NEW.email, true, false, 0, 0, 'madrasah')
        ON CONFLICT ON CONSTRAINT institutions_pkey DO UPDATE SET email = EXCLUDED.email;

        -- Create the admin profile
        INSERT INTO public.profiles (id, institution_id, full_name, role, is_active)
        VALUES (NEW.id, NEW.id, v_full_name, 'madrasah_admin', true)
        ON CONFLICT ON CONSTRAINT profiles_pkey DO UPDATE SET institution_id = EXCLUDED.institution_id, role = 'madrasah_admin';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Make get_my_institution_id more robust
CREATE OR REPLACE FUNCTION public.get_my_institution_id()
RETURNS UUID AS $$
DECLARE
  v_inst_id UUID;
BEGIN
  -- Use a direct query that bypasses RLS
  SELECT institution_id INTO v_inst_id
  FROM public.profiles 
  WHERE id = auth.uid();
  
  RETURN v_inst_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- 3. Ensure all teacher profiles have the correct institution_id and role
-- This is a safety measure in case the trigger messed things up
UPDATE public.profiles p
SET 
  role = 'teacher',
  institution_id = t.institution_id,
  full_name = t.name
FROM public.teachers t
JOIN auth.users u ON u.email = t.phone || '@teacher.deenora.com'
WHERE p.id = u.id AND p.role != 'super_admin';

-- 4. Clean up dummy institutions created for teachers
DELETE FROM public.institutions 
WHERE id IN (
  SELECT id FROM public.profiles WHERE role = 'teacher'
);

-- 5. Re-apply RLS policies to ensure they are using the robust function
-- We'll focus on the core tables first
DROP POLICY IF EXISTS "profiles_institution_access" ON public.profiles;
CREATE POLICY "profiles_institution_access" ON public.profiles FOR SELECT 
USING (
  id = auth.uid() 
  OR 
  (institution_id IS NOT NULL AND institution_id = public.get_my_institution_id()) 
  OR 
  public.check_is_super_admin()
);

DROP POLICY IF EXISTS "institution_select" ON public.institutions;
CREATE POLICY "institution_select" ON public.institutions FOR SELECT 
USING (
  id = public.get_my_institution_id() 
  OR 
  public.check_is_super_admin()
);

DROP POLICY IF EXISTS "classes_isolation" ON public.classes;
CREATE POLICY "classes_isolation" ON public.classes FOR ALL 
USING (
  institution_id = public.get_my_institution_id() 
  OR 
  public.check_is_super_admin()
);

DROP POLICY IF EXISTS "students_isolation" ON public.students;
CREATE POLICY "students_isolation" ON public.students FOR ALL 
USING (
  institution_id = public.get_my_institution_id() 
  OR 
  public.check_is_super_admin()
);

DROP POLICY IF EXISTS "teachers_isolation" ON public.teachers;
CREATE POLICY "teachers_isolation" ON public.teachers FOR ALL 
USING (
  institution_id = public.get_my_institution_id() 
  OR 
  public.check_is_super_admin()
);

DROP POLICY IF EXISTS "attendance_isolation" ON public.attendance;
CREATE POLICY "attendance_isolation" ON public.attendance FOR ALL 
USING (
  institution_id = public.get_my_institution_id() 
  OR 
  public.check_is_super_admin()
);

DROP POLICY IF EXISTS "fees_isolation" ON public.fees;
CREATE POLICY "fees_isolation" ON public.fees FOR ALL 
USING (
  institution_id = public.get_my_institution_id() 
  OR 
  public.check_is_super_admin()
);

DROP POLICY IF EXISTS "ledger_isolation" ON public.ledger;
CREATE POLICY "ledger_isolation" ON public.ledger FOR ALL 
USING (
  institution_id = public.get_my_institution_id() 
  OR 
  public.check_is_super_admin()
);

DROP POLICY IF EXISTS "transactions_isolation" ON public.transactions;
CREATE POLICY "transactions_isolation" ON public.transactions FOR ALL 
USING (
  institution_id = public.get_my_institution_id() 
  OR 
  public.check_is_super_admin()
);

-- Ensure RLS is enabled
ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
