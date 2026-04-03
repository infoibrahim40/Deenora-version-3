-- Update is_super_admin function to include hardcoded super admin emails
CREATE OR REPLACE FUNCTION public.check_is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  ) OR (auth.jwt()->>'email' IN ('kmibrahim@gmail.com', 'thedevomix@gmail.com'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.check_is_super_admin();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Force schema cache reload
NOTIFY pgrst, 'reload config';
