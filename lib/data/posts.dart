// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

List<Post> userFromJson(String str) => List<Post>.from(json.decode(str).map((x) => Post.fromJson(x)));

//String userToJson(List<Status> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Post {
  final String status;
  final List<dynamic> media_ids;
  final String in_reply_to_id;
  final bool sensitive;
  final String spoiler_text;
  final String visibility;
  final String language;

  const Post({
    required this.status,
    required this.media_ids,
    required this.in_reply_to_id,
    required this.sensitive,
    required this.spoiler_text,
    required this.visibility,
    required this.language,
  });

  factory Post.fromJson(Map<String, dynamic> data) => Post(
    status: data["id"]  ??  "",
    media_ids: List.castFrom<dynamic, dynamic>(data['media_ids']),
    in_reply_to_id: data["in_reply_to_id"]  ??  "" ,
    sensitive: data["sensitive"] ?? false,
    spoiler_text: data["spoiler_text"] ?? "",
    visibility: data["visibility"] ?? "none",
    language: data["language"] ?? "" ,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "media_ids": media_ids,
    "in_reply_to_id": in_reply_to_id,
    "sensitive": sensitive,
    "spoiler_text": spoiler_text,
    "visibility": visibility,
    "language": language,
  };
}