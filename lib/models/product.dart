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
  final Map<String, String> sizePrices;
  final String uniqueProductCode;
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
    this.sizePrices = const {},
    this.uniqueProductCode = '',
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
    final titleSlug = cleanTitle.endsWith('-') ? cleanTitle.substring(0, cleanTitle.length - 1) : cleanTitle;

    final String skuPart = sku.trim().isNotEmpty
        ? sku.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s-]'), '').replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'-+'), '-')
        : '';

    final codePart = uniqueProductCode.toLowerCase().trim();

    if (skuPart.isNotEmpty) {
      if (codePart.isNotEmpty) {
        return '$titleSlug-$skuPart-$codePart';
      }
      return '$titleSlug-$skuPart';
    } else {
      if (codePart.isNotEmpty) {
        return '$titleSlug-$codePart';
      }
      return titleSlug;
    }
  }

  Product copyWith({
    String? id,
    String? title,
    String? sku,
    String? departmentId,
    String? categoryId,
    String? subcategoryId,
    String? price,
    double? offerPrice,
    List<CloudinaryImage>? images,
    String? description,
    Map<String, String>? specifications,
    bool? isFeatured,
    bool? isOffer,
    List<String>? tags,
    List<String>? availableSizes,
    Map<String, String>? sizePrices,
    DateTime? createdAt,
    String? uniqueProductCode,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      sku: sku ?? this.sku,
      departmentId: departmentId ?? this.departmentId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      price: price ?? this.price,
      offerPrice: offerPrice ?? this.offerPrice,
      images: images ?? this.images,
      description: description ?? this.description,
      specifications: specifications ?? this.specifications,
      isFeatured: isFeatured ?? this.isFeatured,
      isOffer: isOffer ?? this.isOffer,
      tags: tags ?? this.tags,
      availableSizes: availableSizes ?? this.availableSizes,
      sizePrices: sizePrices ?? this.sizePrices,
      createdAt: createdAt ?? this.createdAt,
      uniqueProductCode: uniqueProductCode ?? this.uniqueProductCode,
    );
  }

  String getPriceLabelForSize(String size) {
    if (sizePrices.containsKey(size) && sizePrices[size]!.isNotEmpty) {
      return sizePrices[size]!;
    }
    if (price.isNotEmpty) {
      return price;
    }
    return 'Inquiry';
  }

  double getPriceForSize(String size) {
    String priceStr = '';
    if (sizePrices.containsKey(size) && sizePrices[size]!.isNotEmpty) {
      priceStr = sizePrices[size]!;
    } else {
      priceStr = price;
    }
    final clean = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  double getActivePriceForSize(String size) {
    final double base = getPriceForSize(size);
    if (isOffer && offerPrice != null && offerPrice! > 0) {
      final double defaultBase = getPriceForSize(availableSizes.isNotEmpty ? availableSizes.first : '');
      if (defaultBase > 0) {
        final double discountRatio = offerPrice! / defaultBase;
        return base * discountRatio;
      }
      return offerPrice!;
    }
    return base;
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

    Map<String, String> parseSizePrices(dynamic val) {
      if (val is Map) {
        return val.map((key, value) {
          return MapEntry(key.toString(), value.toString());
        });
      }
      return {};
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
      sizePrices: parseSizePrices(map['sizePrices']),
      uniqueProductCode: map['uniqueProductCode'] ?? '',
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
      'sizePrices': sizePrices,
      'uniqueProductCode': uniqueProductCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
