import 'item.dart';
import 'user.dart';

class FinderClaim {
  final int id;
  final int itemId;
  final String message;
  final String? supportingInformation;
  final String status;
  final String? supportingFileUrl;
  final FinderItem? item;
  final FinderUser? claimant;
  final DateTime? createdAt;

  const FinderClaim({
    required this.id,
    required this.itemId,
    required this.message,
    required this.status,
    this.supportingInformation,
    this.supportingFileUrl,
    this.item,
    this.claimant,
    this.createdAt,
  });

  factory FinderClaim.fromJson(Map<String, dynamic> json) => FinderClaim(
        id: _toInt(json['id']),
        itemId: _toInt(json['item_id'] ?? (json['item'] is Map ? json['item']['id'] : 0)),
        message: json['message']?.toString() ?? '',
        supportingInformation: json['supporting_information']?.toString(),
        supportingFileUrl: json['supporting_file_url']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        item: json['item'] is Map ? FinderItem.fromJson(Map<String, dynamic>.from(json['item'])) : null,
        claimant: json['claimant'] is Map ? FinderUser.fromJson(Map<String, dynamic>.from(json['claimant'])) : null,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  static int _toInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
}
