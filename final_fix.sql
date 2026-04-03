-- 1. Final verification of function existence
SELECT proname FROM pg_proc WHERE proname = 'check_teacher_login';

-- 2. Ensure permissions are correct
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_teacher_login(text, text) TO anon, authenticated;

-- 3. Force schema reload
NOTIFY pgrst, 'reload schema';
