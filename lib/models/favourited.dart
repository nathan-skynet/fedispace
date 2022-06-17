
class Favourited {
   String id;
   String username;
   String displayName;
   String acct;
   String avatar;



   Favourited({
     required this.id,
     required this.username,
     required this.displayName,
     required this.acct,
     required this.avatar,
});

   factory Favourited.fromJson(Map<String, dynamic> data) => Favourited(
      id: data["id"],
      username: data["username"],
      displayName: data["display_name"],
      acct: data["acct"],
       avatar : data["avatar"]
    );

}




