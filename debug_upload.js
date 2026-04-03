
import fetch from 'node-fetch';
import FormData from 'form-data';

const token = 'oat_MjAz.NFBQQVZmUFBFemdxbFJ4NEh5TF9YcUZTZmlGdzVwY3BUMWc3MXVDajMxNjQyNTQwODA';
const baseUrl = 'https://api.awajdigital.com/api';

async function testUpload() {
  const file_url = 'https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.mp3';
  const name = 'Test Voice ' + Date.now();
  
  console.log('Using mock buffer...');
  const fileBuffer = Buffer.from('mock mp3 content');
  console.log('Mock file size:', fileBuffer.byteLength);
  
  const formData = new FormData();
  formData.append('title', name);
  formData.append('file', Buffer.from(fileBuffer), {
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
