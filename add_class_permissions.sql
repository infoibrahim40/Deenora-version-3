
-- Add allowed_classes and missing permission columns to teacher_permissions
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS allowed_classes UUID[] DEFAULT '{}';
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_manage_exams BOOLEAN DEFAULT FALSE;
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_manage_accounting BOOLEAN DEFAULT FALSE;
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_use_voice_call BOOLEAN DEFAULT FALSE;
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_manage_attendance BOOLEAN DEFAULT FALSE;
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_manage_students BOOLEAN DEFAULT FALSE;
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_manage_classes BOOLEAN DEFAULT FALSE;
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_send_free_sms BOOLEAN DEFAULT FALSE;
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_manage_settings BOOLEAN DEFAULT FALSE;
ALTER TABLE public.teacher_permissions ADD COLUMN IF NOT EXISTS can_view_reports BOOLEAN DEFAULT FALSE;

-- Update the check_teacher_login function to include the new columns
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
