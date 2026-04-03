import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function run() {
  const { data, error } = await supabase.from('profiles').select('id').limit(1);
  console.log('Data:', data);
  console.log('Error:', error);
}

run();
