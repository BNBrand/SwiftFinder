class FinderItem {
  final int id;
  final String type;
  final String title;
  final String description;
  final String location;
  final String status;
  final String occurredOn;
  final String? occurredAt;
  final String? contactPreference;
  final String? identifyingDetails;
  final ItemCategorySummary? category;
  final PosterSummary? poster;
  final List<ItemImage> images;
  final bool isFavorited;
  final DateTime? createdAt;

  const FinderItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.occurredOn,
    this.occurredAt,
    this.contactPreference,
    this.identifyingDetails,
    this.category,
    this.poster,
    this.images = const [],
    this.isFavorited = false,
    this.createdAt,
  });

  FinderItem copyWith({
    bool? isFavorited,
  }) => FinderItem(
    id: id,
    type: type,
    title: title,
    description: description,
    location: location,
    status: status,
    occurredOn: occurredOn,
    occurredAt: occurredAt,
    contactPreference: contactPreference,
    identifyingDetails: identifyingDetails,
    category: category,
    poster: poster,
    images: images,
    isFavorited: isFavorited ?? this.isFavorited,
    createdAt: createdAt,
  );

  factory FinderItem.fromJson(Map<String, dynamic> json) => FinderItem(
    id: _toInt(json['id']),
    type: json['type']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    occurredOn: json['occurred_on']?.toString() ?? '',
    occurredAt: json['occurred_at']?.toString(),
    contactPreference: json['contact_preference']?.toString(),
    identifyingDetails: json['identifying_details']?.toString(),
    category: json['category'] is Map
        ? ItemCategorySummary.fromJson(Map<String, dynamic>.from(json['category'] as Map))
        : null,
    poster: json['poster'] is Map
        ? PosterSummary.fromJson(Map<String, dynamic>.from(json['poster'] as Map))
        : null,
    images: json['images'] is List
        ? (json['images'] as List)
            .whereType<Map>()
            .map((e) => ItemImage.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const [],
    isFavorited: json['is_favorited'] == true,
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );

  static int _toInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
}

class ItemCategorySummary {
  final int id;
  final String name;
  final String slug;
  const ItemCategorySummary({required this.id, required this.name, required this.slug});

  factory ItemCategorySummary.fromJson(Map<String, dynamic> json) => ItemCategorySummary(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
  );
}

class PosterSummary {
  final int id;
  final String name;
  final String? photoPath;
  final String? photoUrl;
  const PosterSummary({required this.id, required this.name, this.photoPath, this.photoUrl});

  factory PosterSummary.fromJson(Map<String, dynamic> json) => PosterSummary(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    name: json['name']?.toString() ?? '',
    photoPath: json['photo_path']?.toString(),
    photoUrl: json['photo_url']?.toString(),
  );
}

class ItemImage {
  final int id;
  final String url;
  const ItemImage({required this.id, required this.url});

  factory ItemImage.fromJson(Map<String, dynamic> json) => ItemImage(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    url: json['url']?.toString() ?? '',
  );
}
