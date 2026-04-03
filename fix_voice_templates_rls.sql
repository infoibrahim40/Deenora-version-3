-- Allow Super Admins to insert voice templates for any institution
DROP POLICY IF EXISTS "Super Admins can insert all voice templates" ON voice_templates;
CREATE POLICY "Super Admins can insert all voice templates" ON voice_templates
    FOR INSERT WITH CHECK (
        public.is_super_admin()
    );

-- Allow Super Admins to delete any voice template
DROP POLICY IF EXISTS "Super Admins can delete all voice templates" ON voice_templates;
CREATE POLICY "Super Admins can delete all voice templates" ON voice_templates
    FOR DELETE USING (
        public.is_super_admin()
    );
