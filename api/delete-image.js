const crypto = require('crypto');
const http = require('https');

module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { public_id } = req.body;

  if (!public_id) {
    return res.status(400).json({ error: 'Missing public_id parameter' });
  }

  // Retrieve Cloudinary credentials from environment variables
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME || 'um227ll2';
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;

  if (!apiKey || !apiSecret) {
    return res.status(500).json({
      error: 'Cloudinary server credentials (CLOUDINARY_API_KEY or CLOUDINARY_API_SECRET) are not configured in Vercel settings.'
    });
  }

  try {
    const timestamp = Math.round(new Date().getTime() / 1000).toString();
    
    // Generate signature: SHA-1 hex hash of 'public_id=<public_id>&timestamp=<timestamp><api_secret>'
    const signaturePayload = `public_id=${public_id}&timestamp=${timestamp}${apiSecret}`;
    const signature = crypto.createHash('sha1').update(signaturePayload).digest('hex');

    // Post to Cloudinary Destroy API
    const postData = JSON.stringify({
      public_id,
      timestamp,
      api_key: apiKey,
      signature
    });

    const options = {
      hostname: 'api.cloudinary.com',
      port: 443,
      path: `/v1_1/${cloudName}/image/destroy`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const request = http.request(options, (response) => {
      let body = '';
      response.on('data', (chunk) => body += chunk);
      response.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (response.statusCode === 200) {
            res.status(200).json(parsed);
          } else {
            res.status(response.statusCode).json({ error: parsed.error?.message || 'Cloudinary deletion failed', details: parsed });
          }
        } catch (e) {
          res.status(500).json({ error: 'Failed to parse Cloudinary response', raw: body });
        }
      });
    });

    request.on('error', (err) => {
      res.status(500).json({ error: 'Network error communicating with Cloudinary', details: err.message });
    });

    request.write(postData);
    request.end();

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
