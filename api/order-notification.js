const https = require('https');
const querystring = require('querystring');

const WEBHOOK_SECRET = process.env.APPS_SCRIPT_WEBHOOK_SECRET || 'HZ_orders_2026_ajay9884875578';
const APPS_SCRIPT_URL = process.env.APPS_SCRIPT_URL || 'https://script.google.com/macros/s/AKfycbz3bHV60Hjor60vqFmALtzk5vfB2F40KhKR3_jlqzMeIIC9kNYH-btv54qCNVkubKns/exec';

/**
 * Follows an HTTP(S) GET request, handling redirects manually.
 */
function followGet(targetUrl, maxRedirects = 5) {
  return new Promise((resolve, reject) => {
    if (maxRedirects <= 0) {
      return reject(new Error('Too many redirects'));
    }

    const parsedUrl = new URL(targetUrl);
    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || 443,
      path: parsedUrl.pathname + parsedUrl.search,
      method: 'GET',
      headers: { 'Accept': 'application/json, text/plain, */*' },
    };

    const req = https.request(options, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let redirectUrl = res.headers.location;
        if (redirectUrl.startsWith('/')) {
          redirectUrl = `${parsedUrl.protocol}//${parsedUrl.host}${redirectUrl}`;
        }
        res.resume();
        return followGet(redirectUrl, maxRedirects - 1)
          .then(resolve)
          .catch(reject);
      }

      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        resolve({ status: res.statusCode, body: body });
      });
    });

    req.on('error', (err) => reject(err));
    req.end();
  });
}

/**
 * Sends order data to Google Apps Script using POST with JSON body.
 * Then follows the 302 redirect as GET to retrieve the response.
 */
function sendPostToAppsScript(targetUrl, payload) {
  return new Promise((resolve, reject) => {
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

    console.log(`[order-notification] POST to ${targetUrl}`);

    const req = https.request(options, (res) => {
      console.log(`[order-notification] POST response status: ${res.statusCode}`);

      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        const redirectUrl = res.headers.location;
        console.log(`[order-notification] Following redirect (GET): ${redirectUrl.substring(0, 100)}...`);
        res.resume();
        return followGet(redirectUrl)
          .then(resolve)
          .catch(reject);
      }

      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        resolve({ status: res.statusCode, body: body });
      });
    });

    req.on('error', (err) => reject(err));
    req.write(postData);
    req.end();
  });
}

/**
 * Sends order data to Google Apps Script using GET with query parameters.
 * This is a fallback method — Apps Script can always read e.parameter for GET requests.
 */
function sendGetToAppsScript(targetUrl, payload) {
  return new Promise((resolve, reject) => {
    // Flatten the payload: convert non-string values to strings, skip 'row' array
    const flatPayload = {};
    for (const [key, value] of Object.entries(payload)) {
      if (key === 'row' || value === null || value === undefined) continue;
      flatPayload[key] = String(value);
    }

    const qs = querystring.stringify(flatPayload);
    const fullUrl = `${targetUrl}?${qs}`;
    console.log(`[order-notification] GET fallback to Apps Script (query length: ${qs.length})`);

    return followGet(fullUrl)
      .then(resolve)
      .catch(reject);
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

    const orderId = orderData.orderId || orderData['Order ID'];
    console.log(`[order-notification] Processing order: ${orderId}`);

    // ── METHOD 1: POST with JSON body ──────────────────────────────────────
    try {
      const postResult = await sendPostToAppsScript(APPS_SCRIPT_URL, securePayload);
      console.log(`[order-notification] POST result: status=${postResult.status}, body=${postResult.body.substring(0, 200)}`);

      // Check if Apps Script successfully processed the order
      if (postResult.body.includes('"success":true')) {
        console.log(`[order-notification] ✅ Order ${orderId} processed successfully via POST`);
        return res.status(200).json({
          success: true,
          method: 'POST',
          result: JSON.parse(postResult.body),
        });
      }

      // If POST returned but Apps Script couldn't parse it, try GET fallback
      console.log(`[order-notification] POST did not return success:true. Trying GET fallback...`);
    } catch (postErr) {
      console.error(`[order-notification] POST method failed: ${postErr.message}. Trying GET fallback...`);
    }

    // ── METHOD 2: GET with query parameters (fallback) ─────────────────────
    try {
      const getResult = await sendGetToAppsScript(APPS_SCRIPT_URL, securePayload);
      console.log(`[order-notification] GET result: status=${getResult.status}, body=${getResult.body.substring(0, 200)}`);

      if (getResult.body.includes('"success":true')) {
        console.log(`[order-notification] ✅ Order ${orderId} processed successfully via GET fallback`);
        return res.status(200).json({
          success: true,
          method: 'GET',
          result: JSON.parse(getResult.body),
        });
      }

      // Return whatever we got
      let parsed;
      try { parsed = JSON.parse(getResult.body); } catch (_) { parsed = { message: getResult.body.substring(0, 500) }; }

      console.error(`[order-notification] Both POST and GET failed for order ${orderId}`);
      return res.status(500).json({
        success: false,
        error: 'Apps Script did not confirm success',
        postAttempt: 'failed or no success confirmation',
        getAttempt: parsed,
      });
    } catch (getErr) {
      console.error(`[order-notification] GET fallback also failed: ${getErr.message}`);
      return res.status(500).json({
        success: false,
        error: 'Both POST and GET methods failed',
        details: getErr.message,
      });
    }
  } catch (err) {
    console.error('[order-notification] Unexpected error:', err.message);
    return res.status(500).json({
      success: false,
      error: 'Failed to deliver notification to Google Apps Script',
      details: err.message,
    });
  }
};
