-- Comprehensive fix for Voice Module RLS
-- This restores policies that might have been dropped by nuclear cleanup scripts

-- 1. Enable RLS on all voice module tables
ALTER TABLE public.voice_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voices ENABLE ROW LEVEL SECURITY;

-- 2. VOICE TEMPLATES POLICIES
DROP POLICY IF EXISTS "voice_templates_isolation" ON public.voice_templates;
CREATE POLICY "voice_templates_isolation" ON public.voice_templates
FOR ALL USING (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
) WITH CHECK (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
);

-- 3. VOICE BROADCASTS POLICIES
DROP POLICY IF EXISTS "voice_broadcasts_isolation" ON public.voice_broadcasts;
CREATE POLICY "voice_broadcasts_isolation" ON public.voice_broadcasts
FOR ALL USING (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
) WITH CHECK (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
);

-- 4. VOICE CALL LOGS POLICIES
DROP POLICY IF EXISTS "voice_call_logs_isolation" ON public.voice_call_logs;
CREATE POLICY "voice_call_logs_isolation" ON public.voice_call_logs
FOR ALL USING (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
) WITH CHECK (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
);

-- 5. WALLETS POLICIES
DROP POLICY IF EXISTS "wallets_isolation" ON public.wallets;
CREATE POLICY "wallets_isolation" ON public.wallets
FOR ALL USING (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
) WITH CHECK (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
);

-- 6. WALLET TRANSACTIONS POLICIES
DROP POLICY IF EXISTS "wallet_transactions_isolation" ON public.wallet_transactions;
CREATE POLICY "wallet_transactions_isolation" ON public.wallet_transactions
FOR ALL USING (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
) WITH CHECK (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
);

-- 7. VOICES POLICIES
DROP POLICY IF EXISTS "voices_isolation" ON public.voices;
CREATE POLICY "voices_isolation" ON public.voices
FOR ALL USING (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
) WITH CHECK (
  institution_id = public.get_authenticated_institution_id() 
  OR public.check_is_super_admin()
);

-- 8. Ensure helper functions use the correct naming convention from supabase_rls.sql
-- and are robust
CREATE OR REPLACE FUNCTION public.check_is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Alias for compatibility
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.check_is_super_admin();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_authenticated_institution_id()
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT institution_id FROM public.profiles 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Alias for compatibility
CREATE OR REPLACE FUNCTION public.get_my_institution_id()
RETURNS UUID AS $$
BEGIN
  RETURN public.get_authenticated_institution_id();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;
