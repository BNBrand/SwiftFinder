import 'user.dart';
import 'item.dart';

class FinderProfile {
  final FinderUser user;
  final int activeListings;
  final int successfulReturns;

  const FinderProfile({required this.user, this.activeListings = 0, this.successfulReturns = 0});

  factory FinderProfile.fromJson(Map<String, dynamic> json) {
    return FinderProfile(
      user: FinderUser.fromJson(Map<String, dynamic>.from((json['user'] as Map?) ?? json)),
      activeListings: _toInt(json['active_listings']),
      successfulReturns: _toInt(json['successful_returns']),
    );
  }

  static int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}
