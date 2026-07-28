class BusinessSettings {
  final String whatsAppNumber;
  final List<String> contactNumbers;
  final String email;
  final String storeAddress;
  final String googleMapsUrl;
  final Map<String, String> socialLinks;
  final String businessHours;
  final String announcementText;
  final String cloudinaryCloudName;
  final String cloudinaryUploadPreset;
  final String cloudinaryFolder;

  // Promo Popup Advertisement Settings
  final bool isPopupActive;
  final String popupImageUrl;
  final String popupLinkUrl;
  final String popupActionText;

  BusinessSettings({
    this.whatsAppNumber = '+919876543210',
    this.contactNumbers = const ['+919876543210'],
    this.email = 'contact@hashzone.com',
    this.storeAddress = '123 Fashion Avenue, Fashion District, City',
    this.googleMapsUrl = 'https://maps.google.com',
    this.socialLinks = const {
      'instagram': 'https://instagram.com/hashzone',
      'facebook': 'https://facebook.com/hashzone',
      'twitter': 'https://twitter.com/hashzone',
      'youtube': 'https://youtube.com',
      'whatsapp': 'https://wa.me/919876543210',
    },
    this.businessHours = 'Mon - Sat: 10:00 AM - 9:00 PM | Sun: 11:00 AM - 7:00 PM',
    this.announcementText = 'WELCOME TO HASH ZONE | DIGITAL CATALOG',
    this.cloudinaryCloudName = 'um227ll2',
    this.cloudinaryUploadPreset = 'hashzone_products',
    this.cloudinaryFolder = 'hashzone/products',
    this.isPopupActive = false,
    this.popupImageUrl = '',
    this.popupLinkUrl = '/products',
    this.popupActionText = 'EXPLORE SPECIAL OFFER',
  });

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    Map<String, String> parseSocial(dynamic val) {
      if (val is Map) {
        return val.map((key, value) => MapEntry(key.toString(), value.toString()));
      }
      return {
        'instagram': 'https://instagram.com/hashzone',
        'facebook': 'https://facebook.com/hashzone',
        'twitter': 'https://twitter.com/hashzone',
        'youtube': 'https://youtube.com',
        'whatsapp': 'https://wa.me/919876543210',
      };
    }

    List<String> parseContacts(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.trim().isNotEmpty) return [val.trim()];
      return ['+919876543210'];
    }

    String announcement = map['announcementText'] ?? 'WELCOME TO HASH ZONE | DIGITAL CATALOG';
    announcement = announcement
        .replaceAll(RegExp(r'CURATED LUXURY\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'LUXURY\s*', caseSensitive: false), '');

    return BusinessSettings(
      whatsAppNumber: map['whatsAppNumber'] ?? '+919876543210',
      contactNumbers: parseContacts(map['contactNumbers'] ?? map['phoneNumber']),
      email: map['email'] ?? 'contact@hashzone.com',
      storeAddress: map['storeAddress'] ?? '123 Fashion Avenue, Fashion District',
      googleMapsUrl: map['googleMapsUrl'] ?? 'https://maps.google.com',
      socialLinks: parseSocial(map['socialLinks']),
      businessHours: map['businessHours'] ?? 'Mon - Sat: 10:00 AM - 9:00 PM',
      announcementText: announcement,
      cloudinaryCloudName: (map['cloudinaryCloudName'] ?? '').toString().isNotEmpty ? map['cloudinaryCloudName'] : 'um227ll2',
      cloudinaryUploadPreset: (map['cloudinaryUploadPreset'] ?? '').toString().isNotEmpty ? map['cloudinaryUploadPreset'] : 'hashzone_products',
      cloudinaryFolder: (map['cloudinaryFolder'] ?? '').toString().isNotEmpty ? map['cloudinaryFolder'] : 'hashzone/products',
      isPopupActive: map['isPopupActive'] ?? false,
      popupImageUrl: map['popupImageUrl'] ?? '',
      popupLinkUrl: map['popupLinkUrl'] ?? '/products',
      popupActionText: map['popupActionText'] ?? 'EXPLORE SPECIAL OFFER',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'whatsAppNumber': whatsAppNumber,
      'contactNumbers': contactNumbers,
      'email': email,
      'storeAddress': storeAddress,
      'googleMapsUrl': googleMapsUrl,
      'socialLinks': socialLinks,
      'businessHours': businessHours,
      'announcementText': announcementText,
      'cloudinaryCloudName': cloudinaryCloudName,
      'cloudinaryUploadPreset': cloudinaryUploadPreset,
      'cloudinaryFolder': cloudinaryFolder,
      'isPopupActive': isPopupActive,
      'popupImageUrl': popupImageUrl,
      'popupLinkUrl': popupLinkUrl,
      'popupActionText': popupActionText,
    };
  }
}
