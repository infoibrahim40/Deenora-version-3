import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://risgwrppzvufbelusxlo.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpc2d3cnBwenZ1ZmJlbHVzeGxvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNzY1ODEsImV4cCI6MjA4Nzk1MjU4MX0.ntPON5RswqkFYjaHLLzVJ3ZJkviJOIB5Pd7vA6uCfmk';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkTable() {
  const { data, error } = await supabase
    .from('profiles')
    .insert([{ id: '00000000-0000-0000-0000-000000000000', full_name: 'test', institution_id: '00000000-0000-0000-0000-000000000000' }])
    .select();

  console.log('Error:', error);
  console.log('Data:', data);
}

checkTable();
