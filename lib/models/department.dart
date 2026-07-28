class Department {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String imageUrl;
  final int order;
  final bool isSizeApplicable;

  Department({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.imageUrl = '',
    this.order = 0,
    this.isSizeApplicable = true,
  });

  factory Department.fromMap(Map<String, dynamic> map, String id) {
    return Department(
      id: id,
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      order: map['order'] ?? 0,
      isSizeApplicable: map['isSizeApplicable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'imageUrl': imageUrl,
      'order': order,
      'isSizeApplicable': isSizeApplicable,
    };
  }
}
