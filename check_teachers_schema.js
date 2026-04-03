
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkSchema() {
  const { data, error } = await supabase.from('teachers').select('*').limit(1);
  if (error) {
    console.error('Error fetching teachers:', error);
  } else {
    console.log('Teacher columns:', Object.keys(data[0] || {}));
  }
}

checkSchema();
