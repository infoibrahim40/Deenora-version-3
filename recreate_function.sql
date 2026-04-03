DROP FUNCTION IF EXISTS public.check_teacher_login(text, text);
DROP FUNCTION IF EXISTS public.check_teacher_login_v2(text, text);

CREATE OR REPLACE FUNCTION public.check_teacher_login(p_phone text, p_pin text)
RETURNS TABLE (
  id uuid,
  institution_id uuid,
  name text,
  phone text,
  is_active boolean,
  permissions jsonb,
  created_at timestamptz,
  institution_data jsonb,
  supabase_email text
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
#variable_conflict use_column
DECLARE
  v_teacher_id uuid;
  v_inst_id uuid;
  v_name text;
  v_email text;
  v_user_id uuid;
  v_instance_id uuid;
BEGIN
  SELECT instance_id INTO v_instance_id FROM auth.users LIMIT 1;
  IF v_instance_id IS NULL THEN v_instance_id := '00000000-0000-0000-0000-000000000000'; END IF;

  SELECT t.id, t.institution_id, t.name 
  INTO v_teacher_id, v_inst_id, v_name
  FROM public.teachers t
  WHERE t.phone = p_phone AND t.login_code = p_pin AND t.is_active = true;

  IF v_teacher_id IS NULL THEN RETURN; END IF;

  v_email := p_phone || '@teacher.deenora.com';
  SELECT u.id INTO v_user_id FROM auth.users u WHERE u.email = v_email;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();
    INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, instance_id, raw_app_meta_data, raw_user_meta_data) 
    VALUES (v_user_id, 'authenticated', 'authenticated', v_email, crypt(p_pin, gen_salt('bf')), now(), now(), now(), v_instance_id, '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb);
    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at) 
    VALUES (v_user_id, v_user_id, format('{"sub":"%s","email":"%s"}', v_user_id, v_email)::jsonb, 'email', v_user_id::text, now(), now(), now());
  ELSE
    UPDATE auth.users SET encrypted_password = crypt(p_pin, gen_salt('bf')), updated_at = now() WHERE auth.users.id = v_user_id;
  END IF;

  INSERT INTO public.profiles (id, institution_id, full_name, role, is_active, permissions)
  VALUES (v_user_id, v_inst_id, v_name, 'teacher', true, (SELECT t.permissions FROM public.teachers t WHERE t.id = v_teacher_id))
  ON CONFLICT ON CONSTRAINT profiles_pkey DO UPDATE 
  SET institution_id = v_inst_id, full_name = v_name, role = 'teacher', permissions = EXCLUDED.permissions;

  RETURN QUERY
  SELECT v_user_id, t.institution_id, t.name, t.phone, t.is_active, t.permissions, t.created_at, to_jsonb(i.*), v_email
  FROM public.teachers t
  JOIN public.institutions i ON t.institution_id = i.id
  WHERE t.id = v_teacher_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_teacher_login(text, text) TO anon, authenticated;
NOTIFY pgrst, 'reload schema';
