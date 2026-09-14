const https = require('https');

const WEBHOOK_SECRET = process.env.APPS_SCRIPT_WEBHOOK_SECRET || 'HZ_orders_2026_ajay9884875578';
const APPS_SCRIPT_URL = process.env.APPS_SCRIPT_URL || 'https://script.google.com/macros/s/AKfycbyKGTx4QzEWlwQg8JuTXk2xDpCH_uD4UkihU3Yosul3jGFHBTpvY5mSGA0PGjTTYCgH/exec';

/**
 * Sends a POST request to Google Apps Script following any 302 redirects.
 */
function sendToAppsScript(targetUrl, payload, maxRedirects = 5) {
  return new Promise((resolve, reject) => {
    if (maxRedirects <= 0) {
      return reject(new Error('Too many redirects while calling Google Apps Script'));
    }

    const postData = typeof payload === 'string' ? payload : JSON.stringify(payload);
    const parsedUrl = new URL(targetUrl);

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || 443,
      path: parsedUrl.pathname + parsedUrl.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    const req = https.request(options, (res) => {
      // Handle Google Apps Script 302 Found redirect
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let redirectUrl = res.headers.location;
        if (redirectUrl.startsWith('/')) {
          redirectUrl = `${parsedUrl.protocol}//${parsedUrl.host}${redirectUrl}`;
        }
        return sendToAppsScript(redirectUrl, payload, maxRedirects - 1)
          .then(resolve)
          .catch(reject);
      }

      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch (_) {
          resolve({ status: res.statusCode, data: { message: body } });
        }
      });
    });

    req.on('error', (err) => reject(err));
    req.write(postData);
    req.end();
  });
}

module.exports = async (req, res) => {
  // CORS Configuration
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Api-Key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const orderData = req.body || {};

    if (!orderData.orderId && !orderData['Order ID']) {
      return res.status(400).json({ error: 'Missing orderId parameter' });
    }

    // Attach webhook secret on the server side so frontend never exposes it
    const securePayload = {
      ...orderData,
      secret: WEBHOOK_SECRET,
      webhookSecret: WEBHOOK_SECRET,
      adminEmail: 'smtind20@gmail.com',
      senderName: 'HASH ZONE DIGITAL STORE',
    };

    const result = await sendToAppsScript(APPS_SCRIPT_URL, securePayload);
    return res.status(200).json({
      success: true,
      result: result.data,
    });
  } catch (err) {
    console.error('[order-notification] Failed to forward to Google Apps Script:', err);
    return res.status(500).json({
      success: false,
      error: 'Failed to deliver notification to Google Apps Script',
      details: err.message,
    });
  }
};
