// ignore_for_file: non_constant_identifier_names


import 'dart:convert';

import 'account.dart';
import 'media_attachement.dart';

/// The [Status] class represents information for a given status (toot)
/// made in a Mastodon instance.
///
/// reference: https://docs.joinmastodon.org/entities/status/
///
/// TODO: fill in all necessary fields
///
List<Status> userFromJson(String str) => List<Status>.from(json.decode(str).map((x) => Status.fromJson(x)));

//String userToJson(List<Status> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Status {
  final String id;
  final String content;
  final Account account;
  final bool favorited;
   final bool reblogged;
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
  final String blurhash;
  final String preview_url;
  final String created_at;
  final int favourites_count;
  final int replies_count;
  final int reblogs_count;
  final List<dynamic> attachement;

  const Status({
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
    required this.reblogs_count,
    required this.attachement,
    required this.blurhash,
  });

  factory Status.fromJson(Map<String, dynamic> data) => Status(
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
          attachement: List.castFrom<dynamic, dynamic>(data['media_attachments']),
          blurhash :  data["media_attachments"][0]["blurhash"] ?? "L5H2EC=PM+yV0g-mq.wG9c010J}I",
          reblogs_count : data["reblogs_count"] ?? "none" ,
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
           "attachement" : attachement,
           "reblogs_count" :  reblogs_count,
  };
}