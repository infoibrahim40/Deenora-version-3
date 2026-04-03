
import fetch from 'node-fetch';
import FormData from 'form-data';

const token = 'oat_MjAz.NFBQQVZmUFBFemdxbFJ4NEh5TF9YcUZTZmlGdzVwY3BUMWc3MXVDajMxNjQyNTQwODA';
const baseUrl = 'https://api.awajdigital.com/api';

async function testUpload() {
  const name = 'Test Voice ' + Date.now();
  const fileBuffer = Buffer.from('ID3\x03\x00\x00\x00\x00\x00\x00'); // Minimal ID3 header
  
  const formData = new FormData();
  formData.append('name', name);
  formData.append('audio', fileBuffer, {
    filename: 'voice.mp3',
    contentType: 'audio/mpeg'
  });

  console.log('Uploading to Awaj...');
  const res = await fetch(`${baseUrl}/voices/upload`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json',
      ...formData.getHeaders()
    },
    body: formData
  });
  
  console.log(`Status: ${res.status}`);
  const text = await res.text();
  console.log('Response:', text);
}

testUpload();
