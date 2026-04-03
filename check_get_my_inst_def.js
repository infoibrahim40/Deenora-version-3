import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function run() {
  const { data, error } = await supabase.rpc('exec_sql', { sql: "SELECT pg_get_functiondef('public.get_my_institution_id'::regproc);" });
  console.log('Data:', data);
  console.log('Error:', error);
}

run();
