/// The [AccountUsers] class represents the information for a
/// given account.
///
/// reference: https://docs.joinmastodon.org/entities/account/
class AccountUsers {
  /// ID of the account in the Mastodon instance.
  final String id;

  /// Username associated to the account.
  final String username;

  /// Display name associated to the account.
  final String displayName;

  /// remote users.
  final String acct;

  /// Whether or not the account is locked.
  final bool isLocked;

  /// Whether or not the account is a bot
  final bool isBot;

  /// URL to the user's set avatar
  final String avatarUrl;

  /// URL to the user's set header
  final String headerUrl;
  final int  followers_count;
  final int  following_count;
  final int  statuses_count;
  final String note;


  AccountUsers(
      {required this.id,
        required this.username,
        required this.displayName,
        required this.acct,
        required this.isLocked,
        required this.isBot,
        required this.avatarUrl,
        required this.headerUrl,
        required this.followers_count,
        required this.following_count,
        required this.statuses_count,
        required this.note,
      });

  /// Given a Json-like [Map] with information for an account,
  /// build and return the respective [AccountUsers] instance.
  ///
  factory AccountUsers.fromJson(Map<String, dynamic> data) {
    return AccountUsers(
      id: data["id"],
      username: data["username"],
      displayName: data["display_name"],
      acct: data["acct"],
      isLocked: data["locked"] ,
      isBot: data["bot"] ,
      avatarUrl: data["avatar"] ,
      headerUrl: data["header"],
      followers_count : data["followers_count"],
      following_count : data["following_count"],
      statuses_count : data["statuses_count"],
      note : data["note"],
    );
  }
}
