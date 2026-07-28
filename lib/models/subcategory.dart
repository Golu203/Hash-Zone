class Subcategory {
  final String id;
  final String name;
  final String slug;
  final String categoryId;
  final int order;

  Subcategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    this.order = 0,
  });

  factory Subcategory.fromMap(Map<String, dynamic> map, String id) {
    return Subcategory(
      id: id,
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      categoryId: map['categoryId'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'categoryId': categoryId,
      'order': order,
    };
  }
}
