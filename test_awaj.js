import fetch from 'node-fetch';
const token = 'oat_MjAz.NFBQQVZmUFBFemdxbFJ4NEh5TF9YcUZTZmlGdzVwY3BUMWc3MXVDajMxNjQyNTQwODA';
const baseUrl = 'https://api.awajdigital.com/api';

async function testEndpoint(path) {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log(`POST ${path}: ${res.status}`);
  const text = await res.text();
  console.log(text);
}

async function run() {
  await testEndpoint('/voice');
  await testEndpoint('/voices');
  await testEndpoint('/voice/upload');
  await testEndpoint('/voices/upload');
  await testEndpoint('/upload/voice');
  await testEndpoint('/upload/voices');
}

run();
