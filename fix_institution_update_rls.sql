-- Fix RLS policy for institutions to allow updates

-- 0. Ensure thedevomix@gmail.com is a super admin
UPDATE public.profiles
SET role = 'super_admin', institution_id = NULL
WHERE id IN (
  SELECT id FROM auth.users WHERE email IN ('kmibrahim@gmail.com', 'thedevomix@gmail.com')
);

UPDATE public.institutions
SET is_super_admin = true
WHERE id IN (
  SELECT id FROM auth.users WHERE email IN ('kmibrahim@gmail.com', 'thedevomix@gmail.com')
);

-- 1. Allow super admins to update any institution
DROP POLICY IF EXISTS "Super admins can update institutions" ON public.institutions;
CREATE POLICY "Super admins can update institutions" ON public.institutions
FOR UPDATE USING (
  public.check_is_super_admin()
) WITH CHECK (
  public.check_is_super_admin()
);

-- 2. Allow regular admins to update their own institution
DROP POLICY IF EXISTS "Admins can update their own institution" ON public.institutions;
CREATE POLICY "Admins can update their own institution" ON public.institutions
FOR UPDATE USING (
  id = public.get_authenticated_institution_id() AND
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'madrasah_admin'
  )
) WITH CHECK (
  id = public.get_authenticated_institution_id() AND
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'madrasah_admin'
  )
);

-- 3. Allow super admins to insert new institutions
DROP POLICY IF EXISTS "Super admins can insert institutions" ON public.institutions;
CREATE POLICY "Super admins can insert institutions" ON public.institutions
FOR INSERT WITH CHECK (
  public.check_is_super_admin()
);

-- 4. Allow super admins to delete institutions
DROP POLICY IF EXISTS "Super admins can delete institutions" ON public.institutions;
CREATE POLICY "Super admins can delete institutions" ON public.institutions
FOR DELETE USING (
  public.check_is_super_admin()
);

-- 5. Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles
FOR UPDATE USING (
  auth.uid() = id
) WITH CHECK (
  auth.uid() = id
);
