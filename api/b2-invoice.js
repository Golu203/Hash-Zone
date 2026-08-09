const crypto = require('crypto');
const https = require('https');

// Backblaze B2 S3 Configuration
const B2_ENDPOINT = process.env.B2_S3_ENDPOINT || 's3.us-east-005.backblazeb2.com';
const B2_REGION = process.env.B2_REGION || 'us-east-005';
const B2_BUCKET = process.env.B2_BUCKET_NAME || 'hashzone-invoice-pdfs';
const B2_KEY_ID = process.env.B2_APPLICATION_KEY_ID || '00511c00e3935300000000001';
const B2_APPLICATION_KEY = process.env.B2_APPLICATION_KEY || 'K005Ocxkes/eNHdnh79CLzs5um+zRQg';

function hmac(key, string, encoding) {
  return crypto.createHmac('sha256', key).update(string).digest(encoding);
}

function hash(string, encoding = 'hex') {
  return crypto.createHash('sha256').update(string).digest(encoding);
}

function getSigningKey(secretKey, dateStamp, regionName, serviceName) {
  const kDate = hmac('AWS4' + secretKey, dateStamp);
  const kRegion = hmac(kDate, regionName);
  const kService = hmac(kRegion, serviceName);
  const kSigning = hmac(kService, 'aws4_request');
  return kSigning;
}

// Generate AWS SigV4 Presigned GET URL
function generatePresignedGetUrl(objectKey, expiresInSeconds = 3600) {
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]/g, '').replace(/\.\d{3}/, '');
  const dateStamp = amzDate.substring(0, 8);

  const credentialScope = `${dateStamp}/${B2_REGION}/s3/aws4_request`;
  const canonicalUri = `/${B2_BUCKET}/${objectKey.split('/').map(encodeURIComponent).join('/')}`;

  const queryParams = {
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Credential': `${B2_KEY_ID}/${credentialScope}`,
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': expiresInSeconds.toString(),
    'X-Amz-SignedHeaders': 'host'
  };

  const canonicalQuery = Object.keys(queryParams)
    .sort()
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(queryParams[key])}`)
    .join('&');

  const canonicalHeaders = `host:${B2_ENDPOINT}\n`;
  const signedHeaders = 'host';
  const payloadHash = 'UNSIGNED-PAYLOAD';

  const canonicalRequest = `GET\n${canonicalUri}\n${canonicalQuery}\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;
  const stringToSign = `AWS4-HMAC-SHA256\n${amzDate}\n${credentialScope}\n${hash(canonicalRequest, 'hex')}`;

  const signingKey = getSigningKey(B2_APPLICATION_KEY, dateStamp, B2_REGION, 's3');
  const signature = hmac(signingKey, stringToSign, 'hex');

  return `https://${B2_ENDPOINT}${canonicalUri}?${canonicalQuery}&X-Amz-Signature=${signature}`;
}

// Perform AWS SigV4 S3 PUT Upload
async function uploadToB2(objectKey, fileBuffer, contentType = 'application/pdf') {
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]/g, '').replace(/\.\d{3}/, '');
  const dateStamp = amzDate.substring(0, 8);

  const payloadHash = hash(fileBuffer, 'hex');
  const canonicalUri = `/${B2_BUCKET}/${objectKey.split('/').map(encodeURIComponent).join('/')}`;
  const canonicalQuery = '';
  const canonicalHeaders = `host:${B2_ENDPOINT}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${amzDate}\n`;
  const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

  const canonicalRequest = `PUT\n${canonicalUri}\n${canonicalQuery}\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;
  const credentialScope = `${dateStamp}/${B2_REGION}/s3/aws4_request`;
  const stringToSign = `AWS4-HMAC-SHA256\n${amzDate}\n${credentialScope}\n${hash(canonicalRequest, 'hex')}`;

  const signingKey = getSigningKey(B2_APPLICATION_KEY, dateStamp, B2_REGION, 's3');
  const signature = hmac(signingKey, stringToSign, 'hex');
  const authorizationHeader = `AWS4-HMAC-SHA256 Credential=${B2_KEY_ID}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  return new Promise((resolve, reject) => {
    const options = {
      hostname: B2_ENDPOINT,
      port: 443,
      path: canonicalUri,
      method: 'PUT',
      headers: {
        'Host': B2_ENDPOINT,
        'Content-Type': contentType,
        'Content-Length': fileBuffer.length,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': payloadHash,
        'Authorization': authorizationHeader
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode === 200 || res.statusCode === 201) {
          resolve({ statusCode: res.statusCode });
        } else {
          reject(new Error(`Backblaze B2 Upload failed (Status ${res.statusCode}): ${body}`));
        }
      });
    });

    req.on('error', (err) => reject(err));
    req.write(fileBuffer);
    req.end();
  });
}

// Perform AWS SigV4 S3 DELETE Object
async function deleteFromB2(objectKey) {
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]/g, '').replace(/\.\d{3}/, '');
  const dateStamp = amzDate.substring(0, 8);

  const payloadHash = hash('', 'hex');
  const canonicalUri = `/${B2_BUCKET}/${objectKey.split('/').map(encodeURIComponent).join('/')}`;
  const canonicalQuery = '';
  const canonicalHeaders = `host:${B2_ENDPOINT}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${amzDate}\n`;
  const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

  const canonicalRequest = `DELETE\n${canonicalUri}\n${canonicalQuery}\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;
  const credentialScope = `${dateStamp}/${B2_REGION}/s3/aws4_request`;
  const stringToSign = `AWS4-HMAC-SHA256\n${amzDate}\n${credentialScope}\n${hash(canonicalRequest, 'hex')}`;

  const signingKey = getSigningKey(B2_APPLICATION_KEY, dateStamp, B2_REGION, 's3');
  const signature = hmac(signingKey, stringToSign, 'hex');
  const authorizationHeader = `AWS4-HMAC-SHA256 Credential=${B2_KEY_ID}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  return new Promise((resolve, reject) => {
    const options = {
      hostname: B2_ENDPOINT,
      port: 443,
      path: canonicalUri,
      method: 'DELETE',
      headers: {
        'Host': B2_ENDPOINT,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': payloadHash,
        'Authorization': authorizationHeader
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode === 200 || res.statusCode === 204) {
          resolve({ statusCode: res.statusCode });
        } else {
          resolve({ statusCode: res.statusCode, body }); // Delete is idempotent
        }
      });
    });

    req.on('error', (err) => reject(err));
    req.end();
  });
}

module.exports = async (req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const { action, orderId, fileName, fileBase64, objectKey } = req.body || req.query || {};

    if (action === 'upload') {
      if (!orderId || !fileName || !fileBase64) {
        return res.status(400).json({ error: 'Missing required parameters: orderId, fileName, fileBase64' });
      }

      // Format validation: filename must end with .pdf
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        return res.status(400).json({ error: 'Validation failed: Only PDF files (.pdf) are allowed.' });
      }

      const fileBuffer = Buffer.from(fileBase64, 'base64');

      // PDF Content validation: check magic header %PDF-
      const pdfHeader = fileBuffer.slice(0, 5).toString('ascii');
      if (pdfHeader !== '%PDF-') {
        return res.status(400).json({ error: 'Validation failed: File content is not a valid PDF document.' });
      }

      const targetKey = `invoices/${orderId}/${fileName}`;
      await uploadToB2(targetKey, fileBuffer, 'application/pdf');

      const presignedUrl = generatePresignedGetUrl(targetKey, 3600);

      return res.status(200).json({
        success: true,
        provider: 'backblaze_b2',
        bucket: B2_BUCKET,
        objectKey: targetKey,
        fileName: fileName,
        contentType: 'application/pdf',
        url: presignedUrl,
        uploadedAt: new Date().toISOString()
      });
    }

    if (action === 'get-access-url') {
      const targetKey = objectKey || (orderId && fileName ? `invoices/${orderId}/${fileName}` : null);
      if (!targetKey) {
        return res.status(400).json({ error: 'Missing objectKey or orderId parameter' });
      }

      const presignedUrl = generatePresignedGetUrl(targetKey, 3600);
      return res.status(200).json({
        success: true,
        url: presignedUrl
      });
    }

    if (action === 'delete') {
      if (!objectKey) {
        return res.status(400).json({ error: 'Missing objectKey parameter' });
      }

      await deleteFromB2(objectKey);
      return res.status(200).json({ success: true });
    }

    return res.status(400).json({ error: 'Invalid or unsupported action parameter' });

  } catch (err) {
    return res.status(500).json({ error: err.message || 'Internal server error processing B2 invoice operation' });
  }
};
