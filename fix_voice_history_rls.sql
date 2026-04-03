-- Fix RLS for voice_broadcasts
DROP POLICY IF EXISTS "Institutions can view their own voice broadcasts" ON voice_broadcasts;
CREATE POLICY "Institutions can view their own voice broadcasts" ON voice_broadcasts
  FOR SELECT USING (
    institution_id = public.get_my_institution_id()
    OR public.is_super_admin()
  );

DROP POLICY IF EXISTS "Institutions can insert their own voice broadcasts" ON voice_broadcasts;
CREATE POLICY "Institutions can insert their own voice broadcasts" ON voice_broadcasts
  FOR INSERT WITH CHECK (
    institution_id = public.get_my_institution_id()
    OR public.is_super_admin()
  );

DROP POLICY IF EXISTS "Institutions can update their own voice broadcasts" ON voice_broadcasts;
CREATE POLICY "Institutions can update their own voice broadcasts" ON voice_broadcasts
  FOR UPDATE USING (
    institution_id = public.get_my_institution_id()
    OR public.is_super_admin()
  );

-- Fix RLS for voice_templates
DROP POLICY IF EXISTS "Institutions can view their own voice templates" ON voice_templates;
CREATE POLICY "Institutions can view their own voice templates" ON voice_templates
  FOR SELECT USING (
    institution_id = public.get_my_institution_id()
    OR public.is_super_admin()
  );

DROP POLICY IF EXISTS "Institutions can insert their own voice templates" ON voice_templates;
CREATE POLICY "Institutions can insert their own voice templates" ON voice_templates
  FOR INSERT WITH CHECK (
    institution_id = public.get_my_institution_id()
    OR public.is_super_admin()
  );

DROP POLICY IF EXISTS "Institutions can update their own voice templates" ON voice_templates;
CREATE POLICY "Institutions can update their own voice templates" ON voice_templates
  FOR UPDATE USING (
    institution_id = public.get_my_institution_id()
    OR public.is_super_admin()
  );

DROP POLICY IF EXISTS "Institutions can delete their own voice templates" ON voice_templates;
CREATE POLICY "Institutions can delete their own voice templates" ON voice_templates
  FOR DELETE USING (
    institution_id = public.get_my_institution_id()
    OR public.is_super_admin()
  );
