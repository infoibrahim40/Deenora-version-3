import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function run() {
  const response = await fetch(`${process.env.SUPABASE_URL}/rest/v1/`, {
    headers: {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY
    }
  });
  const openapi = await response.json();
  console.log('Institutions properties:', openapi.definitions.institutions.properties);
}

run();
