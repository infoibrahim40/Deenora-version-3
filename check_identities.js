import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function run() {
  const { data, error } = await supabase.rpc('exec_sql', { sql: "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'auth' AND table_name = 'identities';" });
  console.log('Data:', data);
  console.log('Error:', error);
}

run();
