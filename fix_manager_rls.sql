-- Allow super admins to update any profile
DROP POLICY IF EXISTS "Super admins can update all profiles" ON public.profiles;
CREATE POLICY "Super admins can update all profiles" ON public.profiles
FOR UPDATE USING (
  public.is_super_admin() OR public.check_is_super_admin()
) WITH CHECK (
  public.is_super_admin() OR public.check_is_super_admin()
);

-- Allow super admins to delete any profile
DROP POLICY IF EXISTS "Super admins can delete all profiles" ON public.profiles;
CREATE POLICY "Super admins can delete all profiles" ON public.profiles
FOR DELETE USING (
  public.is_super_admin() OR public.check_is_super_admin()
);
