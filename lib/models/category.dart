class ItemCategory {
  final int id;
  final String name;
  final String slug;

  const ItemCategory({required this.id, required this.name, required this.slug});

  factory ItemCategory.fromJson(Map<String, dynamic> json) => ItemCategory(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
  );
}
