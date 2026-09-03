const https = require('https');

const MINIMOTH_API_KEY = process.env.MINIMOTH_API_KEY || 'mm_live_e70009ba3e8e44f9fd5bef678e7e6c14194f1a23d4562c2f45a021f7387ff7875809491ef47b6b89ea2f57e60f5f8779';

function makeRequest(path, payload) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(payload);
    const options = {
      hostname: 'api.minimoth.dev',
      port: 443,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'X-Api-Key': MINIMOTH_API_KEY,
      },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, data: { raw: body } });
        }
      });
    });

    req.on('error', (err) => reject(err));
    req.write(postData);
    req.end();
  });
}

module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Api-Key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { action, phone, code, otp } = req.body || {};

  if (!action || !phone) {
    return res.status(400).json({ error: 'Missing action or phone parameter' });
  }

  try {
    if (action === 'send') {
      const result = await makeRequest('/v1/otp/send', { phone });
      return res.status(result.status).json(result.data);
    } else if (action === 'verify') {
      const otpCode = code || otp;
      if (!otpCode) {
        return res.status(400).json({ error: 'Missing code or otp parameter' });
      }
      const result = await makeRequest('/v1/otp/verify', { phone, code: otpCode, otp: otpCode });
      return res.status(result.status).json(result.data);
    } else {
      return res.status(400).json({ error: 'Invalid action. Supported: send, verify' });
    }
  } catch (err) {
    console.error('MiniMoth serverless relay error:', err);
    return res.status(500).json({
      error: 'Failed to communicate with OTP provider',
      details: err.message,
    });
  }
};
