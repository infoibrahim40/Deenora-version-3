import fs from 'fs';

const envFile = fs.readFileSync('.env', 'utf8');
const envVars = {};
envFile.split('\n').forEach(line => {
  const [key, value] = line.split('=');
  if (key && value) envVars[key.trim()] = value.trim();
});

const supabaseUrl = envVars.VITE_SUPABASE_URL;
const supabaseKey = envVars.VITE_SUPABASE_ANON_KEY;

async function checkSchema() {
  const response = await fetch(`${supabaseUrl}/rest/v1/?apikey=${supabaseKey}`);
  const data = await response.json();
  const table = data.definitions.voice_broadcasts;
  console.log('Columns:', Object.keys(table.properties));
}

checkSchema();
