
-- Standardize get_monthly_dues_report to handle both class-specific and global fees
-- This version is optimized for reminders and dashboard reports
DROP FUNCTION IF EXISTS public.get_monthly_dues_report(uuid, uuid, text) CASCADE;

CREATE OR REPLACE FUNCTION public.get_monthly_dues_report(
    p_institution_id UUID,
    p_class_id UUID DEFAULT NULL,
    p_month TEXT DEFAULT NULL
)
RETURNS TABLE (
    student_id UUID,
    student_name TEXT,
    roll INTEGER,
    guardian_phone TEXT,
    total_payable NUMERIC,
    paid_amount NUMERIC,
    balance_due NUMERIC,
    status TEXT
) AS $$
DECLARE
    v_month TEXT := COALESCE(p_month, TO_CHAR(CURRENT_DATE, 'YYYY-MM'));
BEGIN
    RETURN QUERY
    WITH student_list AS (
        SELECT 
            s.id,
            s.student_name,
            s.roll,
            s.guardian_phone,
            s.class_id
        FROM public.students s
        WHERE s.institution_id = p_institution_id
        AND (p_class_id IS NULL OR s.class_id = p_class_id)
    ),
    fee_totals AS (
        SELECT 
            sl.id as student_id,
            SUM(fs.amount)::NUMERIC as total_payable
        FROM student_list sl
        JOIN public.fee_structures fs ON (fs.class_id = sl.class_id OR fs.class_id IS NULL)
        WHERE fs.institution_id = p_institution_id
        GROUP BY sl.id
    ),
    paid_totals AS (
        SELECT 
            f.student_id,
            SUM(f.amount_paid)::NUMERIC as total_paid
        FROM public.fees f
        WHERE f.institution_id = p_institution_id
        AND f.month = v_month
        GROUP BY f.student_id
    )
    SELECT 
        sl.id as student_id,
        sl.student_name,
        sl.roll,
        sl.guardian_phone,
        COALESCE(ft.total_payable, 0) as total_payable,
        COALESCE(pt.total_paid, 0) as paid_amount,
        GREATEST(0, COALESCE(ft.total_payable, 0) - COALESCE(pt.total_paid, 0)) as balance_due,
        CASE 
            WHEN COALESCE(pt.total_paid, 0) >= COALESCE(ft.total_payable, 0) AND COALESCE(ft.total_payable, 0) > 0 THEN 'paid'
            WHEN COALESCE(pt.total_paid, 0) > 0 THEN 'partial'
            ELSE 'unpaid'
        END as status
    FROM student_list sl
    LEFT JOIN fee_totals ft ON sl.id = ft.student_id
    LEFT JOIN paid_totals pt ON sl.id = pt.student_id
    ORDER BY sl.roll ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
