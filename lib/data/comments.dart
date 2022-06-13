// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'account.dart';

/// The [Status] class represents information for a given status (toot)
/// made in a Mastodon instance.
///
/// reference: https://docs.joinmastodon.org/entities/status/
///
/// TODO: fill in all necessary fields
///
List<Comments> userFromJson(String str) => List<Comments>.from(json.decode(str).map((x) => Comments.fromJson(x)));

String userToJson(List<Comments> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Comments {

  /// ID of the status in the Mastodon instance it belongs to
  final String id;

  /// Main content of the status, in HTML format
  final String content;

  /// [Account] instance of the user that created this status
  final Account account;

  /// Whether or not the user has favorited this status
  final bool favorited;

  /// Whether or not the user has reblogged (boosted, retooted) this status
  final bool reblogged;

  /// Whether or not the user has bookmarked this status

  final String visibility;

  final String uri;

  final String url;

  final String in_reply_to_id;

  final String in_reply_to_account_id;

  final bool muted;

  final bool sensitive;

  final String spoiler_text;

  final String language;

  final String avatar;

  final String acct;

  final String attach;

  final String preview_url;

  final String created_at;

  final int favourites_count;

  final int replies_count;

  const Comments({
    required this.id,
    required this.content,
    required this.account,
    required this.favorited,
    required this.reblogged,
    required this.visibility,
    required this.uri,
    required this.url,
    required this.in_reply_to_id,
    required this.in_reply_to_account_id,
    required this.muted,
    required this.sensitive,
    required this.spoiler_text,
    required this.language,
    required this.avatar,
    required this.acct,
    required this.attach,
    required this.preview_url,
    required this.created_at,
    required this.favourites_count,
    required this.replies_count,
  });

  /// Given a Json-like [Map] with information for a status,
  /// build and return the respective [Status] instance.
  ///
  factory Comments.fromJson(Map<String, dynamic> data) => Comments(
    id: data["id"]  ??  "none",
    content: data["content"] ?? "none",
    account: Account.fromJson(data["account"]!),
    favorited: data["favourited"] ?? false,
    reblogged: data["reblogged"] ?? false,
    visibility: data["visibility"] ?? "none",
    uri: data["uri"] ?? "none" ,
    url: data["url"] ?? "none",
    in_reply_to_id: data["in_reply_to_id"] ?? "none",
    in_reply_to_account_id: data["in_reply_to_account_id"] ?? "none",
    muted: data["muted"] ?? false ,
    sensitive: data["sensitive"] ?? false,
    spoiler_text: data["spoiler_text"] ?? "none",
    language: data["language"] ?? "none",
    avatar: data["account"]["avatar"] ?? "none" ,
    acct : data["account"]["acct"] ?? "none",
    attach : data["media_attachments"][0]["url"] ?? "none",
    preview_url : data["media_attachments"][0]["preview_url"] ?? "none",
    created_at : data["created_at"] ?? "none",
    favourites_count : data["favourites_count"] ?? 0,
    replies_count : data["replies_count"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "content": content,
    "account": account,
    "favorited": favorited,
    "reblogged": reblogged,
    "visibility": visibility,
    "uri": uri,
    "url": url,
    "in_reply_to_id": in_reply_to_id,
    "in_reply_to_account_id": in_reply_to_account_id,
    "muted": muted,
    "sensitive": sensitive,
    "spoiler_text": spoiler_text,
    "language": language,
    "avatar" : avatar,
    "acct" :acct,
    "attach" : attach,
    "preview_url" :  preview_url ,
    "created_at" : created_at,
    "favourites_count" : favourites_count,
    "replies_count" : replies_count,
  };
}