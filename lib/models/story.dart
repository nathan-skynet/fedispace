import 'package:fedispace/models/account.dart';

/// Result of the story carousel API call
class StoryCarouselResult {
  final Story? self;
  final List<Story> others;
  StoryCarouselResult({this.self, required this.others});
}


class Story {
  final Account account;
  final List<StoryItem> items;
  bool allSeen;

  Story({
    required this.account,
    required this.items,
    this.allSeen = false,
  });

  /// Parse from the v1.2 carousel format:
  /// { "user": {...}, "nodes": [...], "seen": bool }
  factory Story.fromCarouselNode(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;

    // Build an Account from the carousel user object (has limited fields)
    final account = Account(
      id: userJson['id']?.toString() ?? '',
      username: userJson['username'] ?? userJson['username_acct'] ?? '',
      displayName: userJson['username'] ?? '',
      acct: userJson['username_acct'] ?? userJson['username'] ?? '',
      isLocked: false,
      isBot: false,
      avatarUrl: userJson['avatar'] ?? '',
      headerUrl: '',
      followers_count: 0,
      following_count: 0,
      statuses_count: 0,
      note: '',
    );

    final nodesList = json['nodes'] as List<dynamic>? ?? [];
    final items = nodesList
        .map((node) => StoryItem.fromCarouselNode(node as Map<String, dynamic>))
        .toList();

    return Story(
      account: account,
      items: items,
      allSeen: json['seen'] == true,
    );
  }

  /// Legacy parser (kept for backward compatibility)
  factory Story.fromJson(Map<String, dynamic> json) {
    // Support both formats
    if (json.containsKey('user')) {
      return Story.fromCarouselNode(json);
    }
    return Story(
      account: Account.fromJson(json['account']),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => StoryItem.fromJson(item))
              .toList() ??
          [],
      allSeen: json['seen'] ?? false,
    );
  }
}

class StoryItem {
  final String id;
  final String type; // 'photo' or 'video'
  final String url;
  final String? previewUrl;
  final int duration; // in seconds
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool seen;

  StoryItem({
    required this.id,
    required this.type,
    required this.url,
    this.previewUrl,
    this.duration = 5,
    required this.createdAt,
    this.expiresAt,
    this.seen = false,
  });

  /// Parse from v1.2 carousel node format:
  /// { "id": "...", "type": "photo", "src": "...", "duration": 7, "seen": true, "created_at": "..." }
  factory StoryItem.fromCarouselNode(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'photo',
      url: json['src'] ?? json['url'] ?? '',
      previewUrl: json['preview_url'],
      duration: json['duration'] ?? 5,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      seen: json['seen'] ?? false,
    );
  }

  /// Legacy parser
  factory StoryItem.fromJson(Map<String, dynamic> json) {
    // Support both 'src' and 'url' keys
    return StoryItem(
      id: json['id'].toString(),
      type: json['type'] ?? 'photo',
      url: json['src'] ?? json['url'] ?? '',
      previewUrl: json['preview_url'],
      duration: json['duration'] ?? 5,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      seen: json['seen'] ?? false,
    );
  }
}
