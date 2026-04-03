-- 1. Add pin, permissions, and user_id columns to teachers table
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS pin TEXT;
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{"can_manage_attendance": false, "can_manage_results": false, "allowed_classes": []}'::jsonb;
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- 2. Function to check teacher login and ensure a Supabase user exists
DROP FUNCTION IF EXISTS public.check_teacher_login(text, text);
CREATE OR REPLACE FUNCTION public.check_teacher_login(p_phone text, p_pin text)
RETURNS TABLE (
  id uuid,
  institution_id uuid,
  name text,
  phone text,
  is_active boolean,
  permissions jsonb,
  created_at timestamptz,
  institutions jsonb,
  supabase_email text
) AS $$
DECLARE
  v_teacher_id uuid;
  v_inst_id uuid;
  v_name text;
  v_user_id uuid;
  v_email text;
  v_instance_id uuid;
BEGIN
  -- 1. Verify teacher credentials
  SELECT t.id, t.institution_id, t.name, t.user_id
  INTO v_teacher_id, v_inst_id, v_name, v_user_id
  FROM public.teachers t
  WHERE t.phone = p_phone AND t.pin = p_pin AND t.is_active = true;

  IF v_teacher_id IS NULL THEN
    RAISE EXCEPTION 'Invalid phone number or PIN';
  END IF;

  -- Generate the expected email for this teacher
  v_email := p_phone || '@teacher.deenora.com';

  -- 2. Check if Supabase user exists
  IF v_user_id IS NULL THEN
    SELECT u.id INTO v_user_id FROM auth.users u WHERE u.email = v_email;
  END IF;

  -- 3. If user doesn't exist, create one
  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();
    
    -- Get instance_id
    SELECT instance_id INTO v_instance_id FROM auth.users LIMIT 1;
    IF v_instance_id IS NULL THEN
      v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;

    -- Insert into auth.users
    INSERT INTO auth.users (
      id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, instance_id,
      raw_app_meta_data, raw_user_meta_data
    ) VALUES (
      v_user_id, 'authenticated', 'authenticated', v_email, crypt(p_pin, gen_salt('bf')), now(), now(), now(), v_instance_id,
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb
    );

    -- Insert into auth.identities
    INSERT INTO auth.identities (
      user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
    ) VALUES (
      v_user_id, format('{"sub":"%s","email":"%s"}', v_user_id::text, v_email)::jsonb, 'email', v_user_id::text, now(), now(), now()
    );
  ELSE
    -- Update password if user exists to ensure it matches the PIN
    UPDATE auth.users SET encrypted_password = crypt(p_pin, gen_salt('bf')), updated_at = now() WHERE auth.users.id = v_user_id;
  END IF;

  -- Link user_id to teachers table
  UPDATE public.teachers SET user_id = v_user_id WHERE public.teachers.id = v_teacher_id;

  -- 4. Ensure profile exists
  INSERT INTO public.profiles (id, institution_id, full_name, role, is_active, permissions)
  VALUES (v_user_id, v_inst_id, v_name, 'teacher', true, (SELECT t.permissions FROM public.teachers t WHERE t.id = v_teacher_id))
  ON CONFLICT ON CONSTRAINT profiles_pkey DO UPDATE 
  SET institution_id = v_inst_id, full_name = v_name, role = 'teacher', permissions = EXCLUDED.permissions;

  -- 5. Return teacher data with Supabase user ID
  RETURN QUERY
  SELECT 
    v_user_id AS id,
    t.institution_id AS institution_id,
    t.name AS name,
    t.phone AS phone,
    t.is_active AS is_active,
    t.permissions AS permissions,
    t.created_at AS created_at,
    to_jsonb(i.*) AS institutions,
    v_email AS supabase_email
  FROM public.teachers t
  JOIN public.institutions i ON t.institution_id = i.id
  WHERE t.id = v_teacher_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.check_teacher_login(text, text) TO anon, authenticated;

-- 3. Update RLS policies for teachers table to allow teachers to read their own data
DROP POLICY IF EXISTS "Teachers can view their own data" ON public.teachers;
CREATE POLICY "Teachers can view their own data" ON public.teachers
  FOR SELECT USING (
    user_id = auth.uid()
    OR
    institution_id = public.get_my_institution_id()
    OR
    public.is_super_admin()
  );

-- Allow teachers to update their own pin
DROP POLICY IF EXISTS "Teachers can update their own pin" ON public.teachers;
CREATE POLICY "Teachers can update their own pin" ON public.teachers
  FOR UPDATE USING (
    user_id = auth.uid()
  ) WITH CHECK (
    user_id = auth.uid()
  );

-- 4. Ensure profiles RLS allows teachers to read their own profile
DROP POLICY IF EXISTS "profiles_self_access" ON public.profiles;
CREATE POLICY "profiles_self_access" ON public.profiles
  FOR SELECT USING (id = auth.uid());

DROP POLICY IF EXISTS "profiles_self_update" ON public.profiles;
CREATE POLICY "profiles_self_update" ON public.profiles
  FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
