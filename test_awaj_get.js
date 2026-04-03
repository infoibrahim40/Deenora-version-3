import fetch from 'node-fetch';

const token = 'oat_MjAz.NFBQQVZmUFBFemdxbFJ4NEh5TF9YcUZTZmlGdzVwY3BUMWc3MXVDajMxNjQyNTQwODA';
const baseUrl = 'https://api.awajdigital.com/api';

async function testGet() {
  const res = await fetch(`${baseUrl}/voices`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json'
    }
  });
  
  console.log(`Status: ${res.status}`);
  const text = await res.text();
  console.log(text);
}

testGet();
