class CategoryItem {
  final String id;
  final String name;
  final String slug;
  final String departmentId;
  final int order;

  CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.departmentId,
    this.order = 0,
  });

  factory CategoryItem.fromMap(Map<String, dynamic> map, String id) {
    return CategoryItem(
      id: id,
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      departmentId: map['departmentId'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'departmentId': departmentId,
      'order': order,
    };
  }
}
