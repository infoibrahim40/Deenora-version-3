import { createClient } from '@supabase/supabase-js';
import fetch from 'node-fetch';

const supabaseUrl = 'https://risgwrppzvufbelusxlo.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpc2d3cnBwenZ1ZmJlbHVzeGxvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNzY1ODEsImV4cCI6MjA4Nzk1MjU4MX0.ntPON5RswqkFYjaHLLzVJ3ZJkviJOIB5Pd7vA6uCfmk';
const supabase = createClient(supabaseUrl, supabaseAnonKey);

const token = 'oat_MjAz.NFBQQVZmUFBFemdxbFJ4NEh5TF9YcUZTZmlGdzVwY3BUMWc3MXVDajMxNjQyNTQwODA';
const baseUrl = 'https://api.awajdigital.com/api';

async function run() {
  const { data: templates } = await supabase.from('voice_templates').select('*').eq('file_url', '');
  if (!templates || templates.length === 0) {
    console.log('No templates to fix.');
    return;
  }

  const res = await fetch(`${baseUrl}/voices`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json'
    }
  });
  const awajData = await res.json();
  const awajVoices = awajData.voices || awajData.data || awajData;

  for (const t of templates) {
    const awajVoice = awajVoices.find(v => v.id.toString() === t.provider_voice_id);
    if (awajVoice && awajVoice.previewUrl) {
      await supabase.from('voice_templates').update({ file_url: awajVoice.previewUrl }).eq('id', t.id);
      console.log(`Updated template ${t.id} with previewUrl`);
    }
  }
}
run();
