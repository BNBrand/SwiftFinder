import 'item.dart';
import 'user.dart';

class FinderConversation {
  final int id;
  final int itemId;
  final FinderItem? item;
  final FinderUser? starter;
  final FinderUser? recipient;
  final FinderMessage? latestMessage;

  const FinderConversation({
    required this.id,
    required this.itemId,
    this.item,
    this.starter,
    this.recipient,
    this.latestMessage,
  });

  factory FinderConversation.fromJson(Map<String, dynamic> json) {
    final messages = json['messages'];
    return FinderConversation(
      id: _toInt(json['id']),
      itemId: _toInt(json['item_id']),
      item: json['item'] is Map ? FinderItem.fromJson(Map<String, dynamic>.from(json['item'])) : null,
      starter: json['starter'] is Map ? FinderUser.fromJson(Map<String, dynamic>.from(json['starter'])) : null,
      recipient: json['recipient'] is Map ? FinderUser.fromJson(Map<String, dynamic>.from(json['recipient'])) : null,
      latestMessage: messages is List && messages.isNotEmpty && messages.first is Map
          ? FinderMessage.fromJson(Map<String, dynamic>.from(messages.first))
          : null,
    );
  }

  FinderUser? otherUser(int currentUserId) {
    if (starter?.id == currentUserId) return recipient;
    if (recipient?.id == currentUserId) return starter;
    return starter;
  }

  static int _toInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
}

class FinderMessage {
  final int id;
  final int senderId;
  final String body;
  final FinderUser? sender;
  final DateTime? createdAt;

  const FinderMessage({
    required this.id,
    required this.senderId,
    required this.body,
    this.sender,
    this.createdAt,
  });

  factory FinderMessage.fromJson(Map<String, dynamic> json) => FinderMessage(
        id: _toInt(json['id']),
        senderId: _toInt(json['sender_id']),
        body: json['body']?.toString() ?? '',
        sender: json['sender'] is Map ? FinderUser.fromJson(Map<String, dynamic>.from(json['sender'])) : null,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  static int _toInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
}
