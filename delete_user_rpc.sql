-- RPC to delete a user from auth.users
CREATE OR REPLACE FUNCTION public.delete_user_by_admin(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Check if the caller is a super admin
  IF NOT (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
      AND role = 'super_admin'
    )
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Delete from public tables first (though they might have cascading deletes or triggers)
  DELETE FROM public.profiles WHERE id = p_user_id;
  DELETE FROM public.institutions WHERE id = p_user_id;
  
  -- Delete from auth.users (requires service_role or security definer with enough permissions)
  -- Note: In Supabase, security definer functions can delete from auth.users
  DELETE FROM auth.users WHERE id = p_user_id;
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error deleting user: %', SQLERRM;
    RETURN FALSE;
END;
$$;
