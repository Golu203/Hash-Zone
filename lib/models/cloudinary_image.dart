class CloudinaryImage {
  final String url;
  final String publicId;
  final bool isCover;
  final int displayOrder;
  final int width;
  final int height;
  final String format;

  CloudinaryImage({
    required this.url,
    required this.publicId,
    this.isCover = false,
    this.displayOrder = 1,
    this.width = 0,
    this.height = 0,
    this.format = 'jpg',
  });

  factory CloudinaryImage.fromMap(Map<String, dynamic> map) {
    return CloudinaryImage(
      url: map['url'] ?? '',
      publicId: map['publicId'] ?? '',
      isCover: map['isCover'] ?? false,
      displayOrder: map['displayOrder'] ?? 1,
      width: (map['width'] ?? 0) is int ? map['width'] : int.tryParse(map['width'].toString()) ?? 0,
      height: (map['height'] ?? 0) is int ? map['height'] : int.tryParse(map['height'].toString()) ?? 0,
      format: map['format'] ?? 'jpg',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'publicId': publicId,
      'isCover': isCover,
      'displayOrder': displayOrder,
      'width': width,
      'height': height,
    };
  }

  /// Constructs optimized Cloudinary URL using f_auto, q_auto, and optional responsive width/height
  String toOptimizedUrl({int? width, int? height, String crop = 'limit'}) {
    if (!url.contains('/upload/')) return url;

    final transforms = <String>['f_auto', 'q_auto'];
    if (width != null && width > 0) transforms.add('w_$width');
    if (height != null && height > 0) transforms.add('h_$height');
    if (width != null || height != null) transforms.add('c_$crop');

    final transformString = '${transforms.join(',')}/';
    return url.replaceFirst('/upload/', '/upload/$transformString');
  }

  CloudinaryImage copyWith({
    String? url,
    String? publicId,
    bool? isCover,
    int? displayOrder,
    int? width,
    int? height,
    String? format,
  }) {
    return CloudinaryImage(
      url: url ?? this.url,
      publicId: publicId ?? this.publicId,
      isCover: isCover ?? this.isCover,
      displayOrder: displayOrder ?? this.displayOrder,
      width: width ?? this.width,
      height: height ?? this.height,
      format: format ?? this.format,
    );
  }
}
