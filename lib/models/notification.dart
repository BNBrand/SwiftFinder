class FinderNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? readAt;

  const FinderNotification({required this.id, required this.type, required this.title, required this.message, this.data = const {}, this.createdAt, this.readAt});
  bool get isRead => readAt != null;

  factory FinderNotification.fromJson(Map<String, dynamic> json) => FinderNotification(
    id: json['id']?.toString() ?? '', type: json['type']?.toString() ?? '',
    title: json['title']?.toString() ?? 'SwiftFinder', message: json['message']?.toString() ?? '',
    data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : const {},
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
  );
}
