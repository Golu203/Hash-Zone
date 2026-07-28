class HeroBannerItem {
  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String buttonText;
  final String linkUrl;
  final int order;
  final bool isActive;

  HeroBannerItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.buttonText = 'EXPLORE COLLECTION',
    this.linkUrl = '/products',
    this.order = 0,
    this.isActive = true,
  });

  factory HeroBannerItem.fromMap(Map<String, dynamic> map, String id) {
    return HeroBannerItem(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      buttonText: map['buttonText'] ?? 'EXPLORE COLLECTION',
      linkUrl: map['linkUrl'] ?? '/products',
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'buttonText': buttonText,
      'linkUrl': linkUrl,
      'order': order,
      'isActive': isActive,
    };
  }
}
