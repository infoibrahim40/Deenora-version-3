import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://risgwrppzvufbelusxlo.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpc2d3cnBwenZ1ZmJlbHVzeGxvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNzY1ODEsImV4cCI6MjA4Nzk1MjU4MX0.ntPON5RswqkFYjaHLLzVJ3ZJkviJOIB5Pd7vA6uCfmk';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  const sql = fs.readFileSync('add_teacher_columns.sql', 'utf8');
  const { data, error } = await supabase.rpc('exec_sql', { sql });
  console.log('Data:', data);
  console.log('Error:', error);
}

run();
