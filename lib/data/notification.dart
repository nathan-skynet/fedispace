// ignore_for_file: non_constant_identifier_names


import 'dart:convert';
import 'account.dart';
import 'status.dart';

List<Notif> userFromJson(String str) => List<Notif>.from(json.decode(str).map((x) => Notif.fromJson(x)));

//String userToJson(List<Status> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Notif {
  final String id;
  final String type;
  final Account account;
  final Status status;
  final String attach;
  final String blurhash;
  final String preview_url;
  final String created_at;
  final List<dynamic> attachement;

  const Notif({
    required this.id,
    required this.type,
    required this.account,
    required this.status,
    required this.attach,
    required this.preview_url,
    required this.created_at,
    required this.attachement,
    required this.blurhash,
  });

  factory Notif.fromJson(Map<String, dynamic> data) => Notif(
    id: data["id"]  ??  "none",
    type: data["type"] ?? "none",
    account: Account.fromJson(data["account"]!),
    status: Status.fromJson(data["status"]!),
    attach : data["media_attachments"][0]["url"] ?? "none",
    preview_url : data["media_attachments"][0]["preview_url"] ?? "none",
    created_at : data["created_at"] ?? "none",
    attachement: List.castFrom<dynamic, dynamic>(data['media_attachments']),
    blurhash :  data["media_attachments"][0]["blurhash"] ?? "L5H2EC=PM+yV0g-mq.wG9c010J}I",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "account": account,
     "status" : status,
    "attach" : attach,
    "preview_url" :  preview_url ,
    "created_at" : created_at,
    "attachement" : attachement,
    "blurhash" : blurhash,
  };
}