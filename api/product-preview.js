const https = require('https');

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

function fetchText(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

module.exports = async (req, res) => {
  const { id } = req.query;

  if (!id) {
    return res.status(400).send('Product ID or Slug is required');
  }

  const origin = (req.headers['x-forwarded-proto'] || 'http') + '://' + req.headers.host;

  try {
    // 1. Fetch products from Firestore REST API
    const firestoreUrl = 'https://firestore.googleapis.com/v1/projects/hashzone/databases/(default)/documents/products';
    const firestoreData = await fetchJson(firestoreUrl);
    const products = firestoreData.documents || [];

    // 2. Match the product by ID or Slug matching logic
    const slug = id.toLowerCase().trim();
    const product = products.find(p => {
      const pId = p.name.split('/').pop();
      if (pId === id) return true;

      const fields = p.fields || {};
      const pSlug = fields.slug?.stringValue;
      if (pSlug === id) return true;

      const title = fields.title?.stringValue || '';
      const baseTitleSlug = title.toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-');
      const cleanTitleSlug = baseTitleSlug.endsWith('-') ? baseTitleSlug.slice(0, -1) : baseTitleSlug;
      if (cleanTitleSlug === slug) return true;

      const sku = (fields.sku?.stringValue || '').trim().toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-');
      if (sku && `${cleanTitleSlug}-${sku}` === slug) return true;

      return false;
    });

    // 3. Fetch index.html
    const indexUrl = `${origin}/index.html`;
    let htmlText = await fetchText(indexUrl);

    if (product) {
      const fields = product.fields || {};
      const title = fields.title?.stringValue || 'HASH ZONE';
      let description = fields.description?.stringValue || `Check out ${title} on HASH ZONE Digital Store.`;
      if (description.length > 150) {
        description = description.slice(0, 147) + '...';
      }

      // Find cover image url
      let imageUrl = `${origin}/assets/images/logo_new.jpg`;
      const imagesVal = fields.images?.arrayValue?.values;
      if (imagesVal && imagesVal.length > 0) {
        const coverImg = imagesVal.find(v => {
          const f = v.mapValue?.fields || {};
          return f.isCover?.booleanValue === true;
        });
        const targetImg = coverImg || imagesVal[0];
        const rawUrl = targetImg.mapValue?.fields?.url?.stringValue || '';
        if (rawUrl) {
          // Optimize Cloudinary URL just like in Flutter (inject f_auto, q_auto, w_600)
          if (rawUrl.includes('/upload/')) {
            imageUrl = rawUrl.replace('/upload/', '/upload/f_auto,q_auto,w_600/');
          } else {
            imageUrl = rawUrl;
          }
        }
      }

      // Inject dynamically populated meta tags
      htmlText = htmlText
        .replace(/<title>[^]*?<\/title>/g, `<title>HASH ZONE | ${title}</title>`)
        .replace(/<meta property="og:title" content="[^]*?"/g, `<meta property="og:title" content="${title} | HASH ZONE"`)
        .replace(/<meta property="og:description" content="[^]*?"/g, `<meta property="og:description" content="${description}"`)
        .replace(/<meta property="og:image" content="[^]*?"/g, `<meta property="og:image" content="${imageUrl}"`)
        .replace(/<meta property="og:url" content="[^]*?"/g, `<meta property="og:url" content="${origin}/product/${id}"`)
        .replace(/<meta name="description" content="[^]*?"/g, `<meta name="description" content="${description}"`)
        .replace(/<meta name="twitter:title" content="[^]*?"/g, `<meta name="twitter:title" content="${title} | HASH ZONE"`)
        .replace(/<meta name="twitter:description" content="[^]*?"/g, `<meta name="twitter:description" content="${description}"`)
        .replace(/<meta name="twitter:image" content="[^]*?"/g, `<meta name="twitter:image" content="${imageUrl}"`);
    }

    res.setHeader('Content-Type', 'text/html');
    return res.status(200).send(htmlText);
  } catch (error) {
    console.error('Error fetching preview details:', error);
    // Fallback to serving unmodified index.html
    try {
      const indexUrl = `${origin}/index.html`;
      const htmlText = await fetchText(indexUrl);
      res.setHeader('Content-Type', 'text/html');
      return res.status(200).send(htmlText);
    } catch (_) {
      return res.status(500).send('Error generating preview');
    }
  }
};
