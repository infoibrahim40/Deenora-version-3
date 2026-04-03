
-- Update teachers table to match requested schema
ALTER TABLE public.teachers RENAME COLUMN name TO teacher_name;
ALTER TABLE public.teachers RENAME COLUMN phone TO mobile;
ALTER TABLE public.teachers RENAME COLUMN login_code TO password_hash; -- We'll use this for hashed password
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS designation TEXT;
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive'));
ALTER TABLE public.teachers ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- Create teacher_permissions table
CREATE TABLE IF NOT EXISTS public.teacher_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
    can_view_attendance BOOLEAN DEFAULT FALSE,
    can_take_attendance BOOLEAN DEFAULT FALSE,
    can_view_results BOOLEAN DEFAULT FALSE,
    can_manage_results BOOLEAN DEFAULT FALSE,
    can_view_fees BOOLEAN DEFAULT FALSE,
    can_manage_fees BOOLEAN DEFAULT FALSE,
    can_send_sms BOOLEAN DEFAULT FALSE,
    can_view_students BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(teacher_id)
);

-- Enable RLS
ALTER TABLE public.teacher_permissions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for teacher_permissions
DROP POLICY IF EXISTS "Tenant isolation for teacher_permissions" ON public.teacher_permissions;
CREATE POLICY "Tenant isolation for teacher_permissions" ON public.teacher_permissions
  FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.teachers t
        WHERE t.id = teacher_permissions.teacher_id
        AND (t.institution_id = public.get_my_institution_id() OR public.is_super_admin())
    )
  );

-- Function to check teacher login
CREATE OR REPLACE FUNCTION public.check_teacher_login(p_mobile TEXT, p_password_hash TEXT)
RETURNS TABLE (
    id UUID,
    institution_id UUID,
    teacher_name TEXT,
    designation TEXT,
    photo_url TEXT,
    status TEXT,
    permissions JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.institution_id,
        t.teacher_name,
        t.designation,
        t.photo_url,
        t.status,
        to_jsonb(tp) - 'id' - 'teacher_id' - 'created_at' as permissions
    FROM public.teachers t
    JOIN public.teacher_permissions tp ON t.id = tp.teacher_id
    WHERE t.mobile = p_mobile AND t.password_hash = p_password_hash AND t.status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
