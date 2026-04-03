import fetch from 'node-fetch';

const token = 'oat_MjAz.NFBQQVZmUFBFemdxbFJ4NEh5TF9YcUZTZmlGdzVwY3BUMWc3MXVDajMxNjQyNTQwODA';
const baseUrl = 'https://api.awajdigital.com/api';

async function checkVoices() {
  const res = await fetch(`${baseUrl}/voices`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json'
    }
  });
  const data = await res.json();
  console.log(JSON.stringify(data, null, 2));
}

checkVoices();
