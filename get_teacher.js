import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://risgwrppzvufbelusxlo.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpc2d3cnBwenZ1ZmJlbHVzeGxvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNzY1ODEsImV4cCI6MjA4Nzk1MjU4MX0.ntPON5RswqkFYjaHLLzVJ3ZJkviJOIB5Pd7vA6uCfmk';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function run() {
  const { data, error } = await supabase.from('teachers').select('*').limit(1);
  console.log('Teacher:', data);
  console.log('Error:', error);
}

run();
