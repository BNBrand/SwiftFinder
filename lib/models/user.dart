class FinderUser {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? photoPath;
  final String? photoUrl;
  final DateTime? createdAt;

  const FinderUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.photoPath,
    this.photoUrl,
    this.createdAt,
  });

  factory FinderUser.fromJson(Map<String, dynamic> json) {
    return FinderUser(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      photoPath: json['photo_path']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (photoPath != null) 'photo_path': photoPath,
    if (photoUrl != null) 'photo_url': photoUrl,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  static int _toInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
}
