// ignore_for_file: avoid_print, non_constant_identifier_names

/// Import Flutter
///
import 'dart:convert';
import 'dart:io';


/// Import Fedispace
///
import 'package:fedispace/helpers/auth.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/models/status.dart';

///Import Plugins
///
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_helper.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);
}

class ApiService {
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  String? instanceUrl;

  /// Client key for authentication with Mastodon
  /// (available after app registration)
  String? oauthClientId;

  /// Client secret for authentication with Mastodon
  /// (available after app registration)
  String? oauthClientSecret;

  /// Helper to make authenticated requests to Mastodon.
  OAuth2Helper? helper;
  Account? currentAccount;
  AccountUsers? currentAccountOfUsers;

  http.Client httpClient = http.Client();

  /// Performs a GET request to the specified URL through the API helper
  Future<http.Response> _apiGet(String url) async {
    return await helper!.get(url, httpClient: httpClient);
  }

  /// Performs a POST request to the specified URL through the API helper
  Future<http.Response> _apiPost(String url) async {
    return await helper!.post(url, httpClient: httpClient);
  }

// TODO A VRAIMENT REVOIR !!!!!!!!
  Future<int> createPosts(
      String Token,
      String content,
      String in_reply_to_id,
      List media_ids,
      String sensitive,
      String spoiler_text,
      String visibility) async {
    try {
      var resultat = content.replaceAll("\n", '\\n');

      Map<String, dynamic> result = jsonDecode(
          """{"status": "$resultat",  "application": { "name": "fedispace", "website": "https://git.echelon4.space/sk7n4k3d/fedispace"},
      "media_ids": $media_ids}""");

      var response = await http.post(
        Uri.parse("${instanceUrl!}/api/v1/statuses"),
        body: jsonEncode(result),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Authorization": "Bearer $Token",
        },
      );

      int resultCode = response.statusCode;
      print(result);
      print(response.statusCode.toString());
      print(response.body);
      if (resultCode == 200) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 1,
            channelKey: 'internal',
            title: 'Success post uploaded',
            body: "Your post is on Pixelfed",
          ),
        );
        return 200;
      }
      return 0;
    } catch (err) {
      print("erreur dans la fonction posts");
      print(err);
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'internal',
          title: 'Uploading pots failed',
          body: 'Error : $err',
        ),
      );
      return 0;
    }
  }

  // TODO A VRAIMENT REVOIR !!!!!!!!
  Future<int?> apiPostMedia(String description, List filename) async {
    try {
      List<String> listId = [];
      var uri = Uri.parse("${instanceUrl!}/api/v2/media");
      AccessTokenResponse? token = await helper!.getTokenFromStorage();
      String? Token = token?.accessToken.toString();

      for (int i = 0; i < filename.length; i++) {
        var request = http.MultipartRequest('POST', uri);

        request.headers.addAll({
          'Content-Type': 'multipart/form-data',
          'Authorization': 'Bearer $Token',
        });
        request.fields['description'] = description;
        print(filename.length);
        print(filename[i]);
        request.files.add(await http.MultipartFile(
            "file",
            File(filename[i]).readAsBytes().asStream(),
            File(filename[i]).lengthSync(),
            filename: filename[i].split("/").last));
        var response = await request.send();
        var responsed = await http.Response.fromStream(response);
        final responseData = json.decode(responsed.body);
        print(responsed.body);
        listId.add('"${responseData["id"].toString()}"');
      }
      print(listId);

      return await createPosts(Token.toString(), description, "null", listId,
          "null", "null", "public");
    } catch (err) {
      print("erroor");
      print(err);
      return null;
    }
  }

  Future getNotification() async {
    final apiUrl = "${instanceUrl!}/api/v1/notifications";
    http.Response resp;
    try {
      resp = await _apiGet(
        apiUrl,
      );
    } on Exception {
      throw ApiException(
        "Error connecting to server on `getNotification`",
      );
    }
    if (resp.statusCode == 200) {
      print(resp.body);
      return resp.body;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getClientCredentials`",
    );
  }

  Future<void> getClientCredentials() async {
    final apiUrl = "${instanceUrl!}/api/v1/apps";
    http.Response resp;
    try {
      resp = await httpClient.post(
        Uri.parse(apiUrl),
        body: {
          "client_name": "FediSpace",
          "redirect_uris": featherRedirectUri,
          "scopes": oauthScopes.join(" "),
          "website": "https://git.echelon4.space/sk7n4k3d/fedispace",
        },
      );
    } on Exception {
      throw ApiException(
        "Error connecting to server on `getClientCredentials`",
      );
    }

    if (resp.statusCode == 200) {
      // Setting the client tokens
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      oauthClientId = jsonData["client_id"];
      oauthClientSecret = jsonData["client_secret"];
      return;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getClientCredentials`",
    );
  }

  void setHelper() {
    if (instanceUrl != null &&
        oauthClientId != null &&
        oauthClientSecret != null) {
      helper = getOauthHelper(instanceUrl!, oauthClientId!, oauthClientSecret!);
    } else {
      helper = null;
    }
  }

  Future<void> registerApp(String newInstanceUrl) async {
    // Adding the protocol / scheme if needed
    if (!newInstanceUrl.contains("://")) {
      instanceUrl = "https://$newInstanceUrl";
    } else {
      instanceUrl = newInstanceUrl;
    }

    // This call would set `instanceUrl`, `oauthClientId` and
    // `oauthClientSecret` if everything works as expected
    await getClientCredentials();

    // This call would set `helper`
    setHelper();

    // Persisting information in secure storage
    await secureStorage.write(key: "instanceUrl", value: instanceUrl);
    await secureStorage.write(key: "oauthClientId", value: oauthClientId);
    await secureStorage.write(
        key: "oauthClientSecret", value: oauthClientSecret);
  }

  Future<void> loadApiServiceFromStorage() async {
    instanceUrl = await secureStorage.read(key: "instanceUrl");
    oauthClientId = await secureStorage.read(key: "oauthClientId");
    oauthClientSecret = await secureStorage.read(key: "oauthClientSecret");
    setHelper();
  }

  Future<bool> NodeInfo(domain) async {
    try {
      String apiUrl;
      print(domain);
      if (domain.toString().contains("://")) {
        apiUrl = "${domain}/api/v1/instance";
      } else {
        apiUrl = "https://${domain.toString()}/api/v1/instance";
      }
      print(apiUrl);
      http.Response resp = await http.get(Uri.parse(apiUrl));
      print(jsonDecode(resp.body));
      if (resp.statusCode == 200) {
        print(jsonDecode(resp.body));
        if (jsonDecode(resp.body)[0]["metadata"]["nodeName"] == "Pixelfed" &&
            jsonDecode(resp.body)[0]["config"]["features"]["mobile_apis"] ==
                true) {
          print("ok");
          return true;
        }
        print("pas ok");
        return false;
      }
    } catch (e) {
      print("pas ok");
      return false;
    }
    return false;
  }

  Future<String> GetRepliesBy(String id) async {
    String apiUrl;
    apiUrl = "${instanceUrl!}/api/v1/statuses/$id/favourited_by";
    http.Response resp = await _apiGet(apiUrl);
    if (resp.statusCode == 200) {
      return resp.body;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  Future<List<Status>> getStatusList(String? maxId, int limit, timeLine) async {
    String apiUrl;
    if (timeLine == "home") {
      apiUrl = "${instanceUrl!}/api/v1/timelines/home?limit=20";
    } else {
      apiUrl = "${instanceUrl!}/api/v1/timelines/public?limit=20";
    }
    print(apiUrl);
    if (maxId != null) {
      apiUrl += "&max_id=$maxId";
    }
    http.Response resp = await _apiGet(apiUrl);
    print(resp.statusCode);
    if (resp.statusCode == 200) {
      // The response is a list of json objects
      List<dynamic> jsonDataList = jsonDecode(resp.body);
      return jsonDataList
          .map(
            (statusData) => Status.fromJson(statusData as Map<String, dynamic>),
          )
          .toList();
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  /// Returns the current account as cached in the instance,
  /// retrieving the account details from the API first if needed.
  ///
  Future<Account> getCurrentAccount() async {
    print(currentAccount);
    if (currentAccount != null) {
      return currentAccount!;
    }
    return await getAccount();
  }

  /// Retrieve and return the [Account] instance associated to the current
  /// credentials by querying the API. Updates the `this.currentAccount`
  /// instance attribute in the process.
  ///
  Future<Account> getAccount() async {
    final apiUrl = "${instanceUrl!}/api/v1/accounts/verify_credentials";
    http.Response resp = await _apiGet(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      currentAccount = Account.fromJson(jsonData);
      return currentAccount!;
    }
    print(resp.statusCode);
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getAccount`",
    );
  }

  String? domainURL() {
    return instanceUrl;
  }

  Future<AccountUsers> getUserAccount(id) async {
    final apiUrl = "${instanceUrl!}/api/v1/accounts/${id}";
    http.Response resp = await _apiGet(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      currentAccountOfUsers = AccountUsers.fromJson(jsonData);
      return currentAccountOfUsers!;
    }
    print(resp.statusCode);
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getAccount`",
    );
  }

  Future<Status> statusByID(String statusId) async {
    print("Call Function statuByID");
    final apiUrl = "${instanceUrl!}/api/v1/statuses/$statusId";
    http.Response resp = await _apiGet(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      return Status.fromJson(jsonData);
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getSatusbyID`",
    );
  }

  Future<Status> favoriteStatus(String statusId) async {
    final apiUrl = "${instanceUrl!}/api/v1/statuses/$statusId/favourite";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      return Status.fromJson(jsonData);
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `favoriteStatus`",
    );
  }

  Future<Status> undoFavoriteStatus(String statusId) async {
    final apiUrl = "${instanceUrl!}/api/v1/statuses/$statusId/unfavourite";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      return Status.fromJson(jsonData);
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `undoFavoriteStatus`",
    );
  }

  Future<Status> bookmarkStatus(String statusId) async {
    final apiUrl = "${instanceUrl!}/api/v1/statuses/$statusId/bookmark";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      return Status.fromJson(jsonData);
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `bookmarkStatus`",
    );
  }

  Future<Status> undoBookmarkStatus(String statusId) async {
    final apiUrl = "${instanceUrl!}/api/v1/statuses/$statusId/unbookmark";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      return Status.fromJson(jsonData);
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `undoBookmarkStatus`",
    );
  }

  Future<Status> boostStatus(String statusId) async {
    final apiUrl = "${instanceUrl!}/api/v1/statuses/$statusId/reblog";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      return Status.fromJson(jsonData);
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `boostStatus`",
    );
  }

  Future<Status> undoBoostStatus(String statusId) async {
    final apiUrl = "${instanceUrl!}/api/v1/statuses/$statusId/unreblog";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      return Status.fromJson(jsonData);
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `undoBoostStatus`",
    );
  }

  /// Performs an authenticated query to the API in order to force the log-in
  /// view. In the process, sets the `this.currentAccount` instance attribute.
  ///
  ///
  Future<Account> logIn() async {
    return await getAccount();
  }

  /// Invalidates the stored client tokens server-side and then deletes
  /// all tokens from the secure storage, effectively logging the user out.
  ///
  Future<void> logOut() async {
    final apiUrl = "${instanceUrl!}/oauth/revoke";
    await _apiPost(apiUrl);
    await helper!.removeAllTokens();
    await resetApiServiceState();
  }

  Future<bool> muteUser(userId) async {
    final apiUrl = "${instanceUrl!}/api/v1/accounts/${userId}/mute";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Fluttertoast.showToast(
          msg: "You have muted user",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          // backgroundColor: Colors.red,
          // textColor: Colors.white,
          fontSize: 16.0);
      return true;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  Future<bool> unmuteUser(userId) async {
    final apiUrl = "${instanceUrl!}/api/v1/accounts/${userId}/unmute";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Fluttertoast.showToast(
          msg: "You have unmuted user",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          // backgroundColor: Colors.red,
          // textColor: Colors.white,
          fontSize: 16.0);
      return true;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  Future<bool> followUser(userId) async {
    final apiUrl = "${instanceUrl!}/api/v1/accounts/${userId}/follow";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Fluttertoast.showToast(
          msg: "You have followed user",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          // backgroundColor: Colors.red,
          // textColor: Colors.white,
          fontSize: 16.0);
      return true;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  Future<bool> unfollowUser(userId) async {
    final apiUrl = "${instanceUrl!}/api/v1/accounts/${userId}/unfollow";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Fluttertoast.showToast(
          msg: "You have unfollowed user",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          // backgroundColor: Colors.red,
          // textColor: Colors.white,
          fontSize: 16.0);
      return true;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  Future<bool> blockUser(userId) async {
    final apiUrl = "${instanceUrl!}/api/v1/accounts/${userId}/block";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Fluttertoast.showToast(
          msg: "You have blocked user",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          // backgroundColor: Colors.red,
          // textColor: Colors.white,
          fontSize: 16.0);
      return true;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  Future<bool> unblockUser(userId) async {
    final apiUrl = "${instanceUrl!}/api/v1/accounts/${userId}/unblock";
    http.Response resp = await _apiPost(apiUrl);
    if (resp.statusCode == 200) {
      Fluttertoast.showToast(
          msg: "You have unblocked user",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          // backgroundColor: Colors.red,
          // textColor: Colors.white,
          fontSize: 16.0);
      return true;
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  Future getUserStatus(userId, pageIndex , String? minId) async {
    final String apiUrl;
    if (pageIndex > 1) {
      apiUrl =
          "${instanceUrl!}/api/v1/accounts/${userId}/statuses?limit=16&only_media=true&max_id=${minId.toString()}";
    } else {
      apiUrl = "${instanceUrl!}/api/v1/accounts/${userId}/statuses?limit=16&only_media=true&max_id=0";
    }
    ///////


    /////////
    print(apiUrl);
    http.Response resp = await _apiGet(apiUrl);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw ApiException(
      "Unexpected status code ${resp.statusCode} on `getStatusList`",
    );
  }

  /// Revokes all API service credentials & state variables from the
  /// device's secure storage, and sets their values as `null` in the
  /// instance.
  ///
  Future<void> resetApiServiceState() async {
    await secureStorage.delete(key: "oauthClientId");
    await secureStorage.delete(key: "oauthClientSecret");
    await secureStorage.delete(key: "instanceUrl");

    oauthClientId = null;
    oauthClientSecret = null;
    instanceUrl = null;
    helper = null;
  }
}
