import 'dart:convert';

List<Attachement> userFromJson(String str) => List<Attachement>.from(json.decode(str).map((x) => Attachement.fromJson(x)));

class Attachement {
  final int id;
  final String type;
  final String preview_url;
  final String url;
  final String description;
  final String blurhash;

  Attachement({
    required this.id,
    required this.type,
  required this.preview_url,
    required this.url,
    required this.description,
    required this.blurhash,
  });


  factory Attachement.fromJson(Map<String, dynamic> data) => Attachement(
    id : data["id"] ?? "0",
    type : data["type"] ?? "none",
    preview_url : data["preview_url"] ?? "none",
    url : data["url"] ?? "none",
    description : data["description"] ?? "none",
    blurhash : data["blurhash"] ?? "none",

  );

  Map<String, dynamic> toJson() => {
    "id" : id,
    "type": type,
    "preview_url" :  preview_url ,
    "url" : url,
    "description" : description,
    "blurhash" : blurhash,
  };
}



