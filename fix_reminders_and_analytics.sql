-- Fix for Fee Reminders and Analytics
-- Unifying signatures and ensuring named parameters work correctly

-- 0. Drop existing functions to allow changing return types
-- Using CASCADE to ensure dependent functions are also handled if needed
DROP FUNCTION IF EXISTS public.get_fee_reminder_list(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.get_smart_fee_analytics(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.get_monthly_dues_report(uuid, uuid, text) CASCADE;

-- 1. Redefine get_monthly_dues_report with consistent signature
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
    class_id UUID,
    total_payable NUMERIC,
    total_paid NUMERIC,
    balance_due NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
        sl.class_id,
        COALESCE(ft.total_payable, 0) as total_payable,
        COALESCE(pt.total_paid, 0) as total_paid,
        GREATEST(0, COALESCE(ft.total_payable, 0) - COALESCE(pt.total_paid, 0)) as balance_due
    FROM student_list sl
    LEFT JOIN fee_totals ft ON sl.id = ft.student_id
    LEFT JOIN paid_totals pt ON sl.id = pt.student_id;
END;
$$;

-- 2. Redefine get_fee_reminder_list to use named parameters in internal call
CREATE OR REPLACE FUNCTION public.get_fee_reminder_list(
    p_institution_id UUID,
    p_month TEXT
)
RETURNS TABLE (
    student_id UUID,
    student_name TEXT,
    guardian_phone TEXT,
    class_name TEXT,
    balance_due NUMERIC,
    reminder_type TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_day_of_month INTEGER := EXTRACT(DAY FROM CURRENT_DATE)::INTEGER;
BEGIN
    RETURN QUERY
    SELECT 
        r.student_id,
        r.student_name,
        s.guardian_phone,
        COALESCE(c.class_name, 'No Class'),
        r.balance_due,
        CASE 
            WHEN v_day_of_month >= 25 THEN 'final'
            WHEN v_day_of_month >= 15 THEN 'strong'
            ELSE 'soft'
        END as reminder_type
    FROM get_monthly_dues_report(
        p_institution_id := p_institution_id, 
        p_class_id := NULL, 
        p_month := p_month
    ) r
    JOIN public.students s ON r.student_id = s.id
    LEFT JOIN public.classes c ON s.class_id = c.id
    WHERE r.balance_due > 0;
END;
$$;

-- 3. Fix get_smart_fee_analytics to handle global fees correctly
CREATE OR REPLACE FUNCTION public.get_smart_fee_analytics(
    p_institution_id UUID,
    p_month TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_expected NUMERIC := 0;
    v_total_collected NUMERIC := 0;
    v_total_expense NUMERIC := 0;
    v_student_count INTEGER := 0;
    v_paid_count INTEGER := 0;
    v_unpaid_count INTEGER := 0;
    v_result JSONB;
BEGIN
    -- Count total students
    SELECT COUNT(*) INTO v_student_count 
    FROM public.students 
    WHERE institution_id = p_institution_id;

    -- Calculate Expected Monthly Income (handling global and class-specific fees)
    -- For each student, sum their applicable fees
    SELECT SUM(total_payable) INTO v_total_expected
    FROM (
        SELECT 
            s.id,
            SUM(fs.amount) as total_payable
        FROM public.students s
        JOIN public.fee_structures fs ON (fs.class_id = s.class_id OR fs.class_id IS NULL)
        WHERE s.institution_id = p_institution_id
        AND fs.institution_id = p_institution_id
        GROUP BY s.id
    ) student_fees;

    -- Calculate Collected Amount
    SELECT SUM(amount_paid) INTO v_total_collected
    FROM public.fees
    WHERE institution_id = p_institution_id
    AND month = p_month;

    -- Calculate Expenses
    SELECT SUM(amount) INTO v_total_expense
    FROM public.ledger
    WHERE institution_id = p_institution_id
    AND type = 'expense'
    AND transaction_date LIKE p_month || '%';

    -- Count Paid/Unpaid Students
    SELECT 
        COUNT(CASE WHEN balance_due <= 0 THEN 1 END),
        COUNT(CASE WHEN balance_due > 0 THEN 1 END)
    INTO v_paid_count, v_unpaid_count
    FROM get_monthly_dues_report(
        p_institution_id := p_institution_id, 
        p_class_id := NULL, 
        p_month := p_month
    );

    v_result := jsonb_build_object(
        'expected_income', COALESCE(v_total_expected, 0),
        'prediction', COALESCE(v_total_collected, 0),
        'total_expense', COALESCE(v_total_expense, 0),
        'net_income', COALESCE(v_total_collected, 0) - COALESCE(v_total_expense, 0),
        'student_count', v_student_count,
        'paid_count', v_paid_count,
        'unpaid_count', v_unpaid_count
    );

    RETURN v_result;
END;
$$;
