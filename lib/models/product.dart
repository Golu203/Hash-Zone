import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_image.dart';

class Product {
  final String id;
  final String title;
  final String sku;
  final String departmentId;
  final String categoryId;
  final String subcategoryId;
  final String price;
  final double? offerPrice;
  final List<CloudinaryImage> images;
  final String description;
  final Map<String, String> specifications;
  final bool isFeatured;
  final bool isOffer;
  final List<String> tags;
  final List<String> availableSizes;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.title,
    required this.sku,
    required this.departmentId,
    required this.categoryId,
    this.subcategoryId = '',
    this.price = '',
    this.offerPrice,
    required this.images,
    this.description = '',
    this.specifications = const {},
    this.isFeatured = false,
    this.isOffer = false,
    this.tags = const [],
    this.availableSizes = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CloudinaryImage? get coverImage {
    if (images.isEmpty) return null;
    try {
      return images.firstWhere((img) => img.isCover);
    } catch (_) {
      return images.first;
    }
  }

  String get coverImageUrl {
    return coverImage?.url ?? '';
  }

  List<String> get imageUrls {
    final sorted = List<CloudinaryImage>.from(images);
    sorted.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted.map((e) => e.url).toList();
  }

  String get slug {
    final cleanTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return cleanTitle.endsWith('-') ? cleanTitle.substring(0, cleanTitle.length - 1) : cleanTitle;
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, String> parseSpecs(dynamic val) {
      if (val is Map) {
        return val.map((key, value) => MapEntry(key.toString(), value.toString()));
      }
      return {};
    }

    String parsePrice(dynamic val) {
      if (val == null) return '';
      if (val is num) {
        if (val == 0) return '';
        return '₹${val.toStringAsFixed(0)}';
      }
      return val.toString();
    }

    List<CloudinaryImage> parseImages(dynamic val) {
      if (val is List) {
        return val.map((item) {
          if (item is Map<String, dynamic>) {
            return CloudinaryImage.fromMap(item);
          } else if (item is Map) {
            return CloudinaryImage.fromMap(Map<String, dynamic>.from(item));
          } else if (item is String) {
            return CloudinaryImage(
              url: item,
              publicId: '',
              isCover: true,
              displayOrder: 1,
            );
          }
          return CloudinaryImage(url: '', publicId: '');
        }).where((img) => img.url.isNotEmpty).toList();
      }
      return [];
    }

    return Product(
      id: id,
      title: map['title'] ?? '',
      sku: map['sku'] ?? '',
      departmentId: map['departmentId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      subcategoryId: map['subcategoryId'] ?? '',
      price: parsePrice(map['price']),
      offerPrice: map['offerPrice'] != null ? (map['offerPrice'] as num).toDouble() : null,
      images: parseImages(map['images']),
      description: map['description'] ?? '',
      specifications: parseSpecs(map['specifications']),
      isFeatured: map['isFeatured'] ?? false,
      isOffer: map['isOffer'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      availableSizes: List<String>.from(map['availableSizes'] ?? []),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sku': sku,
      'departmentId': departmentId,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'price': price,
      'offerPrice': offerPrice,
      'images': images.map((img) => img.toMap()).toList(),
      'description': description,
      'specifications': specifications,
      'isFeatured': isFeatured,
      'isOffer': isOffer,
      'tags': tags,
      'availableSizes': availableSizes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
