class Category {
  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final int id;
  final String name;
  final int? parentId;
  final int sortOrder;
  final bool isActive;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      parentId: json['parent_id'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
