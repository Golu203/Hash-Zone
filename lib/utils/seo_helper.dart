import 'dart:html' as html;
import 'dart:convert';

class SeoHelper {
  static void updateMetadata({
    required String title,
    required String description,
    required String keywords,
    required String path,
    String? imageUrl,
    String? jsonLdSchema,
  }) {
    // 1. Title
    html.document.title = title;

    // 2. Canonical URL
    const baseUrl = 'https://www.hashzone.co.in';
    final canonicalUrl = '$baseUrl$path';
    _updateLinkTag('canonical', canonicalUrl);

    // 3. Standard Meta tags
    _updateMetaTag('description', description);
    _updateMetaTag('keywords', keywords);

    // 4. Open Graph Tags
    _updateMetaProperty('og:title', title);
    _updateMetaProperty('og:description', description);
    _updateMetaProperty('og:type', 'website');
    _updateMetaProperty('og:url', canonicalUrl);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      _updateMetaProperty('og:image', imageUrl);
    } else {
      _updateMetaProperty('og:image', '$baseUrl/assets/images/logo_new.jpg');
    }

    // 5. Twitter Meta Tags
    _updateMetaTag('twitter:card', 'summary_large_image');
    _updateMetaTag('twitter:title', title);
    _updateMetaTag('twitter:description', description);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      _updateMetaTag('twitter:image', imageUrl);
    } else {
      _updateMetaTag('twitter:image', '$baseUrl/assets/images/logo_new.jpg');
    }

    // 6. JSON-LD Schema
    if (jsonLdSchema != null && jsonLdSchema.isNotEmpty) {
      _updateJsonLdScript(jsonLdSchema);
    } else {
      // Default Organization / LocalBusiness Schema
      final defaultSchema = {
        "@context": "https://schema.org",
        "@type": "ClothingStore",
        "name": "HASH ZONE",
        "alternateName": "Sree Meenakshi Textile (SMT)",
        "description": "Premium wholesale clothing manufacturer and bulk garment factory in Tiruppur, India. Custom OEM cotton apparel exporter.",
        "url": baseUrl,
        "logo": "$baseUrl/assets/images/logo_new.jpg",
        "address": {
          "@type": "PostalAddress",
          "streetAddress": "Tiruppur HPO",
          "addressLocality": "Tiruppur",
          "addressRegion": "Tamil Nadu",
          "postalCode": "641601",
          "addressCountry": "IN"
        },
        "geo": {
          "@type": "GeoCoordinates",
          "latitude": "11.1085",
          "longitude": "77.3411"
        },
        "telephone": "+91 99999 99999",
        "priceRange": "\$\$"
      };
      _updateJsonLdScript(json.encode(defaultSchema));
    }
  }

  static void _updateMetaTag(String name, String content) {
    var element = html.document.head?.querySelector('meta[name="$name"]');
    if (element == null) {
      element = html.MetaElement()
        ..setAttribute('name', name);
      html.document.head?.append(element);
    }
    element.setAttribute('content', content);
  }

  static void _updateMetaProperty(String property, String content) {
    var element = html.document.head?.querySelector('meta[property="$property"]');
    if (element == null) {
      element = html.MetaElement()
        ..setAttribute('property', property);
      html.document.head?.append(element);
    }
    element.setAttribute('content', content);
  }

  static void _updateLinkTag(String rel, String href) {
    var element = html.document.head?.querySelector('link[rel="$rel"]');
    if (element == null) {
      element = html.LinkElement()
        ..setAttribute('rel', rel);
      html.document.head?.append(element);
    }
    element.setAttribute('href', href);
  }

  static void _updateJsonLdScript(String jsonLd) {
    var element = html.document.head?.querySelector('script[type="application/ld+json"]');
    if (element == null) {
      element = html.ScriptElement()
        ..setAttribute('type', 'application/ld+json');
      html.document.head?.append(element);
    }
    element.text = jsonLd;
  }
}
