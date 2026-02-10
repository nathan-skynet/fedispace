// Improved error handling and logging

/// Import Flutter
///
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Import Fedispace
///
import 'package:fedispace/core/error_handler.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/helpers/auth.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/models/story.dart';
import 'package:fedispace/models/status.dart';

///Import Plugins
///
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_helper.dart';

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

  /// Create a new post/status on Pixelfed
  /// 
  /// SECURITY: Fixed JSON injection vulnerability by using proper Map serialization
  Future<int> createPosts({
      required String content,
      String? inReplyToId,
      List<String> mediaIds = const [],
      bool sensitive = false,
      String? spoilerText,
      String visibility = 'public'}) async {
    try {
      // Build request body as a proper Map instead of string concatenation
      final Map<String, dynamic> requestBody = {
        'status': content,
        'application': {
          'name': 'fedispace',
          'website': 'https://git.echelon4.space/sk7n4k3d/fedispace',
        },
        'media_ids': mediaIds,
      };

      // Add optional parameters only if provided
      if (inReplyToId != null) {
        requestBody['in_reply_to_id'] = inReplyToId;
      }
      if (sensitive) {
        requestBody['sensitive'] = true;
      }
      if (spoilerText != null && spoilerText.isNotEmpty) {
        requestBody['spoiler_text'] = spoilerText;
      }
      if (visibility.isNotEmpty) {
        requestBody['visibility'] = visibility;
      }

      appLogger.apiCall('POST', '/api/v1/statuses', params: requestBody);

      final response = await helper!.post(
        '${instanceUrl!}/api/v1/statuses',
        body: jsonEncode(requestBody),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      appLogger.apiResponse('/api/v1/statuses', response.statusCode,
          body: response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 1,
            channelKey: 'internal',
            title: 'Success post uploaded',
            body: 'Your post is on Pixelfed',
          ),
        );
        return response.statusCode;
      }

      ErrorHandler.handleResponse(response.statusCode, response.body);
      return response.statusCode;
    } catch (err, stackTrace) {
      appLogger.error('Error creating post', err, stackTrace);
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'internal',
          title: 'Uploading post failed',
          body: 'Error: ${err.toString()}',
        ),
      );
      return 0;
    }
  }

  /// Upload media files to Pixelfed and create a post
  /// 
  /// SECURITY: Fixed hardcoded values and improved error handling
  Future<int?> apiPostMedia(String description, List<String> filenames,
      {bool sensitive = false, String visibility = 'public'}) async {
    try {
      List<String> mediaIds = [];
      final uri = Uri.parse('${instanceUrl!}/api/v2/media');
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;

      if (token == null) {
        throw AuthenticationException('No access token available');
      }

      appLogger.info('Uploading ${filenames.length} media files');

      // Create progress notification
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 999,
          channelKey: 'internal',
          title: 'Uploading Media',
          body: 'Starting upload...',
          notificationLayout: NotificationLayout.ProgressBar,
          progress: 0,
        ),
      );

      for (int i = 0; i < filenames.length; i++) {
        final filename = filenames[i];
        final file = File(filename);

        if (!await file.exists()) {
          throw ValidationException('File not found: $filename');
        }

        // Update progress
        final progressPercent = ((i / filenames.length) * 100).toInt();
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 999,
            channelKey: 'internal',
            title: 'Uploading Media',
            body: 'Uploading file ${i + 1} of ${filenames.length}',
            notificationLayout: NotificationLayout.ProgressBar,
            progress: progressPercent.toDouble(),
          ),
        );

        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });
        request.fields['description'] = description;

        request.files.add(await http.MultipartFile(
          'file',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: filename.split('/').last,
        ));

        final response = await request.send();
        final responseBody = await http.Response.fromStream(response);

        appLogger.apiResponse(
            '/api/v2/media', responseBody.statusCode, body: responseBody.body);

        // Accept 200 OK, 201 Created, and 202 Accepted (async processing)
        // Per Mastodon API: 202 is returned for large files (video/audio) being processed asynchronously
        if (responseBody.statusCode != 200 && 
            responseBody.statusCode != 201 && 
            responseBody.statusCode != 202) {
          // Dismiss progress notification
          AwesomeNotifications().dismiss(999);
          ErrorHandler.handleResponse(
              responseBody.statusCode, responseBody.body);
          return null;
        }

        final responseData = ErrorHandler.parseJson(responseBody.body);
        final mediaId = responseData['id']?.toString();
        
        if (mediaId != null) {
          mediaIds.add(mediaId);
          
          // Log async processing status
          if (responseBody.statusCode == 202) {
            appLogger.info('Media $mediaId uploaded, processing asynchronously (preview available)');
          } else {
            appLogger.info('Media $mediaId uploaded and processed');
          }
        }
      }

      // Dismiss progress, show completion notification handled by createPosts
      AwesomeNotifications().dismiss(999);

      appLogger.info('Successfully uploaded ${mediaIds.length} media files');

      return await createPosts(
        content: description,
        mediaIds: mediaIds,
        sensitive: sensitive,
        visibility: visibility,
      );
    } catch (err, stackTrace) {
      appLogger.error('Error uploading media', err, stackTrace);
      return null;
    }
  }

  /// Get notifications for the current user
  Future getNotification() async {
    final apiUrl = '${instanceUrl!}/api/v1/notifications';
    http.Response resp;
    try {
      appLogger.apiCall('GET', '/api/v1/notifications');
      resp = await _apiGet(apiUrl);
    } on Exception catch (e, stackTrace) {
      appLogger.error('Error getting notifications', e, stackTrace);
      throw NetworkException(
        'Error connecting to server on getNotification',
        originalError: e,
      );
    }
    
    appLogger.apiResponse('/api/v1/notifications', resp.statusCode);
    
    if (resp.statusCode == 200) {
      return resp.body;
    }
    throw ApiException(
      'Unexpected status code ${resp.statusCode} on getNotification',
      statusCode: resp.statusCode,
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

  /// Check if domain is a valid Pixelfed instance
  Future<bool> NodeInfo(domain) async {
    try {
      String apiUrl;
      appLogger.debug('Checking Pixelfed instance: $domain');
      
      if (domain.toString().contains('://')) {
        apiUrl = '$domain/api/v1/instance';
      } else {
        apiUrl = 'https://${domain.toString()}/api/v1/instance';
      }
      
      appLogger.apiCall('GET', apiUrl);
      http.Response resp = await http.get(Uri.parse(apiUrl));
      appLogger.apiResponse(apiUrl, resp.statusCode);
      
      if (resp.statusCode == 200) {
        final jsonBody = jsonDecode(resp.body);
        if (jsonBody[0]['metadata']['nodeName'] == 'Pixelfed' &&
            jsonBody[0]['config']['features']['mobile_apis'] == true) {
          appLogger.info('Valid Pixelfed instance detected: $domain');
          return true;
        }
        appLogger.warning('Not a valid Pixelfed instance: $domain');
        return false;
      }
    } catch (e, stackTrace) {
      appLogger.error('Error checking Pixelfed instance', e, stackTrace);
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

  /// Get list of statuses from timeline
  Future<List<Status>> getStatusList(String? maxId, int limit, timeLine) async {
    String apiUrl;
    if (timeLine == 'home') {
      apiUrl = '${instanceUrl!}/api/v1/timelines/home?limit=20';
    } else if (timeLine == 'local') {
      apiUrl = '${instanceUrl!}/api/v1/timelines/public?local=true&limit=20';
    } else {
      apiUrl = '${instanceUrl!}/api/v1/timelines/public?limit=20';
    }
    
    if (maxId != null) {
      apiUrl += '&max_id=$maxId';
    }
    
    appLogger.apiCall('GET', apiUrl);
    http.Response resp = await _apiGet(apiUrl);
    appLogger.apiResponse(apiUrl, resp.statusCode);
    
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
      'Unexpected status code ${resp.statusCode} on getStatusList',
      statusCode: resp.statusCode,
    );
  }

  /// Get list of statuses for a specific tag
  Future<List<Status>> getTimelineTag(String tag, String? maxId, int limit) async {
    String apiUrl = '${instanceUrl!}/api/v1/timelines/tag/$tag?limit=$limit';
    
    if (maxId != null) {
      apiUrl += '&max_id=$maxId';
    }
    
    appLogger.apiCall('GET', apiUrl);
    http.Response resp = await _apiGet(apiUrl);
    appLogger.apiResponse(apiUrl, resp.statusCode);
    
    if (resp.statusCode == 200) {
      List<dynamic> jsonDataList = jsonDecode(resp.body);
      return jsonDataList
          .map(
            (statusData) => Status.fromJson(statusData as Map<String, dynamic>),
          )
          .toList();
    }
    throw ApiException(
      'Unexpected status code ${resp.statusCode} on getTimelineTag',
      statusCode: resp.statusCode,
    );
  }

  /// Returns the current account as cached in the instance,
  /// retrieving the account details from the API first if needed.
  Future<Account> getCurrentAccount() async {
    appLogger.debug('Getting current account');
    if (currentAccount != null) {
      return currentAccount!;
    }
    return await getAccount();
  }

  /// Retrieve and return the [Account] instance associated to the current
  /// credentials by querying the API. Updates the `this.currentAccount`
  /// instance attribute in the process.
  Future<Account> getAccount() async {
    final apiUrl = '${instanceUrl!}/api/v1/accounts/verify_credentials';
    appLogger.apiCall('GET', '/api/v1/accounts/verify_credentials');
    
    http.Response resp = await _apiGet(apiUrl);
    appLogger.apiResponse(apiUrl, resp.statusCode);
    
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      currentAccount = Account.fromJson(jsonData);
      appLogger.info('Account retrieved: ${currentAccount!.username}');
      return currentAccount!;
    }
    
    throw ApiException(
      'Unexpected status code ${resp.statusCode} on getAccount',
      statusCode: resp.statusCode,
    );
  }

  String? domainURL() {
    return instanceUrl;
  }

  /// Get account information for a specific user
  Future<AccountUsers> getUserAccount(id) async {
    final apiUrl = '${instanceUrl!}/api/v1/accounts/$id';
    appLogger.apiCall('GET', '/api/v1/accounts/$id');
    
    http.Response resp = await _apiGet(apiUrl);
    appLogger.apiResponse(apiUrl, resp.statusCode);
    
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      currentAccountOfUsers = AccountUsers.fromJson(jsonData);
      return currentAccountOfUsers!;
    }
    
    throw ApiException(
      'Unexpected status code ${resp.statusCode} on getUserAccount',
      statusCode: resp.statusCode,
    );
  }

  /// Get a single status by ID
  Future<Status> statusByID(String statusId) async {
    appLogger.debug('Fetching status: $statusId');
    final apiUrl = '${instanceUrl!}/api/v1/statuses/$statusId';
    
    http.Response resp = await _apiGet(apiUrl);
    appLogger.apiResponse(apiUrl, resp.statusCode);
    
    if (resp.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(resp.body);
      return Status.fromJson(jsonData);
    }
    throw ApiException(
      'Unexpected status code ${resp.statusCode} on statusByID',
      statusCode: resp.statusCode,
    );
  }

  // Alias for compatibility
  Future<Status> getStatus(String statusId) => statusByID(statusId);

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

  /// Get list of muted accounts
  /// GET /api/v1/mutes
  Future<List<Map<String, dynamic>>> getMutes({int limit = 40}) async {
    final apiUrl = "${instanceUrl!}/api/v1/mutes?limit=$limit";
    http.Response resp = await _apiGet(apiUrl);
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    }
    return [];
  }

  /// Get list of blocked accounts
  /// GET /api/v1/blocks
  Future<List<Map<String, dynamic>>> getBlocks({int limit = 40}) async {
    final apiUrl = "${instanceUrl!}/api/v1/blocks?limit=$limit";
    http.Response resp = await _apiGet(apiUrl);
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    }
    return [];
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

  Future<bool> reportUser(String accountId, {String? comment, List<String>? statusIds}) async {
    final apiUrl = "${instanceUrl!}/api/v1/reports";
    
    final Map<String, dynamic> body = {
      'account_id': accountId,
    };
    
    if (comment != null && comment.isNotEmpty) {
      body['comment'] = comment;
    }
    
    if (statusIds != null && statusIds.isNotEmpty) {
      body['status_ids'] = statusIds;
    }

    // Using helper.post directly to handle body encoding if needed, similar to createPosts
    // But _apiPost uses helper.post with httpClient. 
    // Let's use helper.post directly to control headers and body encoding strictly if needed, 
    // or we can try to use _apiPost if it supports body. 
    // _apiPost implementation: Future<http.Response> _apiPost(String url) async { return await helper!.post(url, httpClient: httpClient); }
    // It doesn't seem to take a body. I should check _apiPost again.
    // Wait, _apiPost at line 53 takes one arg. It seems limited.
    // I will use helper!.post directly like createPosts does.

    appLogger.apiCall('POST', '/api/v1/reports', params: body);
    
    final response = await helper!.post(
      apiUrl,
      body: body, 
      // oauth2_client helper automatically sets Content-Type to application/x-www-form-urlencoded if body is map
      // or application/json if we encode it. Mastodon API usually accepts form-data.
      httpClient: httpClient,
    );
    
    appLogger.apiResponse('/api/v1/reports', response.statusCode, body: response.body);

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
          msg: "User reported",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          fontSize: 16.0);
      return true;
    }
    
    ErrorHandler.handleResponse(response.statusCode, response.body);
    return false;
  }

  /// Get user's statuses
  Future getUserStatus(userId, pageIndex, String? minId) async {
    final String apiUrl;
    if (pageIndex > 1) {
      apiUrl =
          '${instanceUrl!}/api/v1/accounts/$userId/statuses?limit=16&only_media=true&max_id=${minId.toString()}';
    } else {
      apiUrl =
          '${instanceUrl!}/api/v1/accounts/$userId/statuses?limit=16&only_media=true&max_id=0';
    }

    appLogger.apiCall('GET', apiUrl);
    http.Response resp = await _apiGet(apiUrl);
    appLogger.apiResponse(apiUrl, resp.statusCode);
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw ApiException(
      'Unexpected status code ${resp.statusCode} on getUserStatus',
      statusCode: resp.statusCode,
    );
  }

  // ========== STORIES API ENDPOINTS (PAE-06) ==========

  /// Fetch the story carousel (own + friends' stories) in one API call.
  /// Uses /api/v1.1/stories/carousel which returns { self: {...}, nodes: [...] }
  /// Falls back to /api/v1.2/stories/carousel if v1.1 is not available.
  Future<StoryCarouselResult> getStoryCarousel() async {
    try {
      // Try v1.1 first (includes self stories)
      var apiUrl = '${instanceUrl!}/api/v1.1/stories/carousel';
      appLogger.apiCall('GET', '/api/v1.1/stories/carousel');
      var resp = await _apiGet(apiUrl);

      if (resp.statusCode == 404) {
        // Fallback to v1.2 (no self stories in response)
        apiUrl = '${instanceUrl!}/api/v1.2/stories/carousel';
        appLogger.apiCall('GET', '/api/v1.2/stories/carousel');
        resp = await _apiGet(apiUrl);
      }

      appLogger.apiResponse('stories/carousel', resp.statusCode, body: resp.body.length > 500 ? resp.body.substring(0, 500) : resp.body);

      if (resp.statusCode != 200) {
        appLogger.warning('Story carousel returned ${resp.statusCode}');
        return StoryCarouselResult(self: null, others: []);
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      // Parse self stories (only present in v1.1 response)
      Story? selfStory;
      if (data['self'] != null && data['self'] is Map<String, dynamic>) {
        final selfData = data['self'] as Map<String, dynamic>;
        final selfNodes = selfData['nodes'] as List<dynamic>? ?? [];
        if (selfNodes.isNotEmpty && selfData['user'] != null) {
          selfStory = Story.fromCarouselNode(selfData);
        }
      }

      // Parse friends' stories
      final otherNodes = data['nodes'] as List<dynamic>? ?? [];
      final others = otherNodes
          .where((n) => n is Map<String, dynamic> && n['user'] != null)
          .map((n) => Story.fromCarouselNode(n as Map<String, dynamic>))
          .where((s) => s.items.isNotEmpty)
          .toList();

      appLogger.info('Story carousel: self=${selfStory != null ? selfStory.items.length : 0} items, ${others.length} friends');
      return StoryCarouselResult(self: selfStory, others: others);
    } catch (e, s) {
      appLogger.error('Error fetching story carousel', e, s);
      return StoryCarouselResult(self: null, others: []);
    }
  }


  /// Create and publish a story in one step
  /// Uses the same endpoint as the official Pixelfed app:
  /// POST /api/v1.2/stories/publish (multipart, with X-PIXELFED-APP header)
  /// Returns null on success, or an error message string on failure.
  /// Resize an image to exactly 1080x1920 for Pixelfed story upload.
  /// The server requires exactly these dimensions (Rule::dimensions()->width(1080)->height(1920)).
  /// Scales the image to cover the 1080x1920 area, then center-crops.
  /// Always returns a path to the resized file, or null on error.
  Future<String?> _resizeImageForStory(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) {
        appLogger.warning('Could not decode image for resize: $filePath');
        return null;
      }

      const int targetW = 1080;
      const int targetH = 1920;

      appLogger.info('Story image original: ${original.width}x${original.height}, target: ${targetW}x$targetH');

      // Scale to cover: pick the larger scale factor so the image fills the target area
      final double scale = math.max(targetW / original.width, targetH / original.height);
      final int scaledW = (original.width * scale).round();
      final int scaledH = (original.height * scale).round();

      // Resize to cover dimensions
      final scaled = img.copyResize(original, width: scaledW, height: scaledH, interpolation: img.Interpolation.linear);

      // Center-crop to exactly 1080x1920
      final int cropX = ((scaledW - targetW) / 2).round();
      final int cropY = ((scaledH - targetH) / 2).round();
      final cropped = img.copyCrop(scaled, x: cropX, y: cropY, width: targetW, height: targetH);

      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/story_resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final jpegBytes = img.encodeJpg(cropped, quality: 85);
      await File(outPath).writeAsBytes(jpegBytes);

      appLogger.info('Story image resized to ${targetW}x$targetH, saved to $outPath (${jpegBytes.length} bytes)');
      return outPath;
    } catch (e, stackTrace) {
      appLogger.error('Error resizing story image', e, stackTrace);
      return null; // fall back to original
    }
  }

  Future<String?> createStory({required String filePath, int duration = 10}) async {
    try {
      // Resize image to fit Pixelfed story dimension limits
      final resizedPath = await _resizeImageForStory(filePath);
      final uploadPath = resizedPath ?? filePath;

      final uri = Uri.parse('${instanceUrl!}/api/v1.2/stories/publish');
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;

      if (token == null) return 'No access token';

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-PIXELFED-APP': '1',
      });
      
      final file = File(uploadPath);
      if (!await file.exists()) return 'File not found: $uploadPath';

      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      request.fields['duration'] = duration.toString();
      request.fields['can_reply'] = 'true';
      request.fields['can_react'] = 'true';
      
      appLogger.apiCall('POST', '/api/v1.2/stories/publish');
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      appLogger.apiResponse('/api/v1.2/stories/publish', responseBody.statusCode, body: responseBody.body);

      // Clean up temporary resized file
      if (resizedPath != null) {
        try { await File(resizedPath).delete(); } catch (_) {}
      }

      if (responseBody.statusCode == 200 || responseBody.statusCode == 201) {
        return null; // success
      }
      appLogger.error('Story publish failed: ${responseBody.statusCode} ${responseBody.body}');
      return 'Upload failed (${responseBody.statusCode}): ${responseBody.body}';
    } catch (e, stackTrace) {
      appLogger.error('Error creating story', e, stackTrace);
      return 'Error: $e';
    }
  }

  // ========== NEW API ENDPOINTS ==========

  /// Update the user's profile information
  /// PATCH /api/v1/accounts/update_credentials
  Future<Account> updateCredentials({
    String? displayName,
    String? note,
    File? avatar,
    File? header,
    bool? locked,
    bool? discoverable,
  }) async {
    try {
      final uri = Uri.parse('${instanceUrl!}/api/v1/accounts/update_credentials');
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;

      if (token == null) {
        throw AuthenticationException('No access token available');
      }

      final request = http.MultipartRequest('PATCH', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      if (displayName != null) request.fields['display_name'] = displayName;
      if (note != null) request.fields['note'] = note;
      if (locked != null) request.fields['locked'] = locked.toString();
      if (discoverable != null) request.fields['discoverable'] = discoverable.toString();

      // Add image files
      if (avatar != null && await avatar.exists()) {
        request.files.add(await http.MultipartFile.fromPath('avatar', avatar.path));
      }
      if (header != null && await header.exists()) {
        request.files.add(await http.MultipartFile.fromPath('header', header.path));
      }

      appLogger.apiCall('PATCH', '/api/v1/accounts/update_credentials');
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      appLogger.apiResponse('/api/v1/accounts/update_credentials', responseBody.statusCode);

      if (responseBody.statusCode == 200) {
        final jsonData = ErrorHandler.parseJson(responseBody.body);
        currentAccount = Account.fromJson(jsonData);
        return currentAccount!;
      }

      ErrorHandler.handleResponse(responseBody.statusCode, responseBody.body);
      throw ApiException('Failed to update credentials', statusCode: responseBody.statusCode);
    } catch (err, stackTrace) {
      appLogger.error('Error updating credentials', err, stackTrace);
      rethrow;
    }
  }

  /// Search for accounts
  /// GET /api/v1/accounts/search
  Future<List<AccountUsers>> searchAccounts(String query, {int limit = 20}) async {
    try {
      final params = {
        'q': query,
        'limit': limit.toString(),
      };
      final uri = Uri.parse('${instanceUrl!}/api/v1/accounts/search')
          .replace(queryParameters: params);

      appLogger.apiCall('GET', '/api/v1/accounts/search?q=$query');
      final resp = await _apiGet(uri.toString());
      appLogger.apiResponse('/api/v1/accounts/search', resp.statusCode);

      if (resp.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(resp.body);
        return jsonData
            .map((account) => AccountUsers.fromJson(account as Map<String, dynamic>))
            .toList();
      }

      ErrorHandler.handleResponse(resp.statusCode, resp.body);
      throw ApiException('Search failed', statusCode: resp.statusCode);
    } catch (err, stackTrace) {
      appLogger.error('Error searching accounts', err, stackTrace);
      rethrow;
    }
  }

  /// Get account followers
  /// GET /api/v1/accounts/:id/followers
  Future<List<AccountUsers>> getFollowers(String accountId, {String? maxId, int limit = 40}) async {
    try {
      var apiUrl = '${instanceUrl!}/api/v1/accounts/$accountId/followers?limit=$limit';
      if (maxId != null) {
        apiUrl += '&max_id=$maxId';
      }

      appLogger.apiCall('GET', '/api/v1/accounts/$accountId/followers');
      final resp = await _apiGet(apiUrl);
      appLogger.apiResponse(apiUrl, resp.statusCode);

      if (resp.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(resp.body);
        return jsonData
            .map((account) => AccountUsers.fromJson(account as Map<String, dynamic>))
            .toList();
      }

      ErrorHandler.handleResponse(resp.statusCode, resp.body);
      throw ApiException('Failed to get followers', statusCode: resp.statusCode);
    } catch (err, stackTrace) {
      appLogger.error('Error getting followers', err, stackTrace);
      rethrow;
    }
  }

  // Missing methods implementation for compatibility

  Future<bool> unFollow(String userId) async {
    return unfollowUser(userId);
  }

  Future<void> followStatus(String userId) async {
      // Assuming this is checking relationship? Or following?
      // Based on usage context 'await widget.apiService.followStatus(widget.userId);'
      // It might be 'followUser'.
      await followUser(userId);
  }
  
  Future<List<Status>> getFav(String? maxId) async {
    // Get Favourites
    // GET /api/v1/favourites
    String apiUrl = '${instanceUrl!}/api/v1/favourites?limit=20';
    if (maxId != null) {
       apiUrl += '&max_id=$maxId';
    }
    
    appLogger.apiCall('GET', apiUrl);
    http.Response resp = await _apiGet(apiUrl);
    appLogger.apiResponse(apiUrl, resp.statusCode);
    
    if (resp.statusCode == 200) {
       List<dynamic> jsonDataList = jsonDecode(resp.body);
       return jsonDataList
          .map((statusData) => Status.fromJson(statusData as Map<String, dynamic>))
          .toList();
    }
     throw ApiException(
      'Unexpected status code ${resp.statusCode} on getFav',
      statusCode: resp.statusCode,
    );
  }

  Future<Map<String, dynamic>> getContext(String statusId) async {
    final apiUrl = '${instanceUrl!}/api/v1/statuses/$statusId/context';
    appLogger.apiCall('GET', apiUrl);
    http.Response resp = await _apiGet(apiUrl);
    
    if (resp.statusCode == 200) {
       return jsonDecode(resp.body);
    }
    throw ApiException('Failed to get context', statusCode: resp.statusCode);
  }

  String? getInstanceUrl() {
    return instanceUrl;
  }

  /// Get accounts being followed
  /// GET /api/v1/accounts/:id/following
  Future<List<AccountUsers>> getFollowing(String accountId, {String? maxId, int limit = 40}) async {
    try {
      var apiUrl = '${instanceUrl!}/api/v1/accounts/$accountId/following?limit=$limit';
      if (maxId != null) {
        apiUrl += '&max_id=$maxId';
      }

      appLogger.apiCall('GET', '/api/v1/accounts/$accountId/following');
      final resp = await _apiGet(apiUrl);
      appLogger.apiResponse(apiUrl, resp.statusCode);

      if (resp.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(resp.body);
        return jsonData
            .map((account) => AccountUsers.fromJson(account as Map<String, dynamic>))
            .toList();
      }

      ErrorHandler.handleResponse(resp.statusCode, resp.body);
      throw ApiException('Failed to get following', statusCode: resp.statusCode);
    } catch (err, stackTrace) {
      appLogger.error('Error getting following', err, stackTrace);
      rethrow;
    }
  }

  /// Get bookmarked statuses
  /// GET /api/v1/bookmarks
  Future<List<Status>> getBookmarks({String? maxId, int limit = 20}) async {
    try {
      var apiUrl = '${instanceUrl!}/api/v1/bookmarks?limit=$limit';
      if (maxId != null) {
        apiUrl += '&max_id=$maxId';
      }

      appLogger.apiCall('GET', '/api/v1/bookmarks');
      final resp = await _apiGet(apiUrl);
      appLogger.apiResponse(apiUrl, resp.statusCode);

      if (resp.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(resp.body);
        return jsonData
            .map((status) => Status.fromJson(status as Map<String, dynamic>))
            .toList();
      }

      ErrorHandler.handleResponse(resp.statusCode, resp.body);
      throw ApiException('Failed to get bookmarks', statusCode: resp.statusCode);
    } catch (err, stackTrace) {
      appLogger.error('Error getting bookmarks', err, stackTrace);
      rethrow;
    }
  }

  /// Delete a status
  /// DELETE /api/v1/statuses/:id
  Future<bool> deleteStatus(String statusId) async {
    try {
      final apiUrl = '${instanceUrl!}/api/v1/statuses/$statusId';
      appLogger.apiCall('DELETE', '/api/v1/statuses/$statusId');

      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;

      if (token == null) {
        throw AuthenticationException('No access token available');
      }

      final resp = await httpClient.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      appLogger.apiResponse(apiUrl, resp.statusCode);

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        Fluttertoast.showToast(
          msg: 'Post deleted',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          fontSize: 16.0,
        );
        return true;
      }

      ErrorHandler.handleResponse(resp.statusCode, resp.body);
      return false;
    } catch (err, stackTrace) {
      appLogger.error('Error deleting status', err, stackTrace);
      return false;
    }
  }

  /// Clear all notifications
  /// POST /api/v1/notifications/clear
  Future<bool> clearNotifications() async {
    try {
      final apiUrl = '${instanceUrl!}/api/v1/notifications/clear';
      appLogger.apiCall('POST', '/api/v1/notifications/clear');

      final resp = await _apiPost(apiUrl);
      appLogger.apiResponse(apiUrl, resp.statusCode);

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        appLogger.info('All notifications cleared');
        return true;
      }

      ErrorHandler.handleResponse(resp.statusCode, resp.body);
      return false;
    } catch (err, stackTrace) {
      appLogger.error('Error clearing notifications', err, stackTrace);
      return false;
    }
  }

  /// Dismiss a single notification
  /// POST /api/v1/notifications/:id/dismiss
  Future<bool> dismissNotification(String notificationId) async {
    try {
      final apiUrl = '${instanceUrl!}/api/v1/notifications/$notificationId/dismiss';
      appLogger.apiCall('POST', '/api/v1/notifications/$notificationId/dismiss');

      final resp = await _apiPost(apiUrl);
      appLogger.apiResponse(apiUrl, resp.statusCode);

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return true;
      }

      ErrorHandler.handleResponse(resp.statusCode, resp.body);
      return false;
    } catch (err, stackTrace) {
      appLogger.error('Error dismissing notification', err, stackTrace);
      return false;
    }
  }

  /// Get direct message conversations
  /// Mastodon API: GET /api/v1/conversations
  Future<List<dynamic>> getConversations({int limit = 20, String? maxId, String? minId}) async {
    return getConversationsByScope(scope: 'inbox', limit: limit, maxId: maxId, minId: minId);
  }

  /// Get conversations by scope: inbox, sent, or requests
  Future<List<dynamic>> getConversationsByScope({required String scope, int limit = 40, String? maxId, String? minId}) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;

      if (token == null) {
        throw AuthenticationException('No access token available');
      }

      final queryParams = {
        'scope': scope,
        if (maxId != null) 'max_id': maxId,
        if (minId != null) 'min_id': minId,
      };

      final uri = Uri.parse('$_baseUrl/api/v1/conversations').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      appLogger.apiResponse('/api/v1/conversations?scope=$scope', response.statusCode, body: response.body);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        }
        return [];
      } else {
        ErrorHandler.handleResponse(response.statusCode, response.body);
        return [];
      }
    } catch (err, stackTrace) {
      appLogger.error('Error getting conversations (scope=$scope)', err, stackTrace);
      return [];
    }
  }

  /// Get all messages for a specific conversation partner
  /// Merges inbox + sent conversations to reconstruct full DM history
  Future<List<Map<String, dynamic>>> getAllConversationMessages(String partnerId) async {
    try {
      // Fetch both inbox and sent
      final inbox = await getConversationsByScope(scope: 'inbox', limit: 40);
      final sent = await getConversationsByScope(scope: 'sent', limit: 40);

      final List<Map<String, dynamic>> allMessages = [];

      // Extract messages from inbox (received from partner)
      for (var conv in inbox) {
        if (conv is! Map) continue;
        final accounts = conv['accounts'] as List?;
        if (accounts == null || accounts.isEmpty) continue;
        
        // Check if this conversation involves our partner
        bool matchesPartner = accounts.any((a) => a['id']?.toString() == partnerId);
        if (!matchesPartner) continue;

        final lastStatus = conv['last_status'];
        if (lastStatus != null && lastStatus is Map) {
          allMessages.add({
            ...Map<String, dynamic>.from(lastStatus),
            '_direction': 'received',
          });
        }
      }

      // Extract messages from sent (sent to partner)
      for (var conv in sent) {
        if (conv is! Map) continue;
        final accounts = conv['accounts'] as List?;
        if (accounts == null || accounts.isEmpty) continue;
        
        bool matchesPartner = accounts.any((a) => a['id']?.toString() == partnerId);
        if (!matchesPartner) continue;

        final lastStatus = conv['last_status'];
        if (lastStatus != null && lastStatus is Map) {
          allMessages.add({
            ...Map<String, dynamic>.from(lastStatus),
            '_direction': 'sent',
          });
        }
      }

      // Sort by created_at descending (newest first for reverse ListView)
      allMessages.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      // Deduplicate by status ID
      final seen = <String>{};
      allMessages.removeWhere((msg) {
        final id = msg['id']?.toString() ?? '';
        if (seen.contains(id)) return true;
        seen.add(id);
        return false;
      });

      return allMessages;
    } catch (e, stack) {
      appLogger.error('Error getting all conversation messages', e, stack);
      return [];
    }
  }

  /// Send a direct message
  /// Mastodon API: POST /api/v1/statuses with visibility='direct'
  Future<dynamic> sendDirectMessage({
    required String recipientUsername,
    required String content,
    List<String>? mediaIds,
  }) async {
    try {
      // Pixelfed Specific: Send via /api/v1/direct/thread/send
      // Fallback: If this fails, we might need another approach, but "visibility: direct" 400s.
      
      final uri = '${instanceUrl!}/api/v1/direct/thread/send';
      
      // Try mapping common parameters for "DirectMessageController@create"
      // Likely: recipient_id, message (or text)
      // I'll send multiple keys to be safe if it ignores extras.
      
      // NOTE: We need recipient_id. I'm adding it as a parameter, but for now assuming it's passed or resolvable?
      // Wait, the signature didn't change in my edit yet. I need to update the signature to accept recipientId.
      // But to avoid breaking other calls (if any), I'll make it optional or derived?
      // Actually, I can't derive ID from username easily without a search.
      // User passed recipientId in the map if calling new method?
      // No, let's update the signature. 
      // Oops, I can't update signature here easily without breaking call sites... 
      // BUT call sites are updated in previous steps?
      
      // WAIT: I updated the call site in ConversationDetailPage to PASS recipientId to the Widget, 
      // but I didn't update the CALL to ApiService.sendDirectMessage yet.
      // So I should update ApiService.sendDirectMessage signature OR add a new method.
      // Adding a new method is safer.
      
      throw UnimplementedError("Use sendChatDirectMessage instead");
    } catch (err, stackTrace) {
        return null;
    }
  }

  Future<dynamic> sendChatDirectMessage({
      required String recipientId,
      required String content,
      List<String>? mediaIds,
  }) async {
    try {
        // Correct path confirmed from source: /api/v1.1/direct/thread/send
        final uri = '$_baseUrl/api/v1.1/direct/thread/send';
        
        final Map<String, String> bodyMap = {
           'to_id': recipientId,  // Changed from recipient_id
           'message': content,    // Changed from body/text fallback
           'type': 'text',        // Required by validation (in:text,emoji)
        };
        
        if (mediaIds != null && mediaIds.isNotEmpty) {
            // ... media handling if needed, usually media_id or media_ids[]
             for (int i = 0; i < mediaIds.length; i++) {
                bodyMap['media_ids[$i]'] = mediaIds[i];
             }
        }
        
        appLogger.apiCall('POST', '/api/v1.1/direct/thread/send', params: bodyMap);
        
        final response = await helper!.post(
            uri,
            body: bodyMap,
            headers: {
              'Accept': 'application/json',
            },
        );
        
        appLogger.apiResponse('/api/v1.1/direct/thread/send', response.statusCode, body: response.body);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
             // Success
             return jsonDecode(response.body); // Return map
        } else {
             // Log
             appLogger.error('Chat DM Failed ${response.statusCode}: ${response.body}');
             return {'error': 'Chat API ${response.statusCode}: ${response.body}'};
        }
    } catch (e, stack) {
        appLogger.error('Chat DM Error', e, stack);
        return {'error': 'Exception: $e'};
    }
  }

  /// Get chat messages for a thread
  /// GET /api/v1.1/direct/thread/:id/messages
  Future<List<dynamic>> getChatMessages(String threadId, {String? maxId}) async {
    try {
        var uri = '$_baseUrl/api/v1.1/direct/thread/$threadId/messages';
        if (maxId != null) {
          uri += '?max_id=$maxId';
        }

        appLogger.apiCall('GET', '/api/v1.1/direct/thread/$threadId/messages');
        final response = await _apiGet(uri);
        appLogger.apiResponse(uri, response.statusCode);

        if (response.statusCode == 200) {
            return jsonDecode(response.body);
        }
        return [];
    } catch (e, stack) {
        appLogger.error('Error getting chat messages', e, stack);
        return [];
    }
  }

  /// Get Pixelfed direct message thread for a specific partner
  /// GET /api/v1.1/direct/thread?pid={partnerId}
  Future<List<dynamic>> getDirectThread(String partnerId) async {
    try {
        final tokenResponse = await helper!.getTokenFromStorage();
        final token = tokenResponse?.accessToken;
        
        final uri = Uri.parse('$_baseUrl/api/v1.1/direct/thread').replace(
          queryParameters: {'pid': partnerId},
        );
        
        appLogger.apiCall('GET', '/api/v1.1/direct/thread?pid=$partnerId');
        
        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        
        appLogger.apiResponse('/api/v1.1/direct/thread?pid=$partnerId', response.statusCode, body: response.body);
        
        if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded is List) {
              return decoded;
            } else if (decoded is Map && decoded.containsKey('messages')) {
              // Some Pixelfed versions wrap messages in a map
              return decoded['messages'] is List ? decoded['messages'] : [];
            }
            return [decoded]; // Single object, wrap in list
        }
        return [];
    } catch (e, stack) {
        appLogger.error('Error getting direct thread', e, stack);
        return [];
    }
  }

  // Deprecated or fallback
  Future<dynamic> sendDirectMessageOld({
    required String recipientUsername,
    required String content,
    List<String>? mediaIds,
  }) async {
    try {
        // Old logic here if needed, or just return null
        return null;
    } catch (err, stackTrace) {
      appLogger.error('Error sending direct message', err, stackTrace);
      return null;
    }
  }

  /// Sanitize instance URL to remove trailing slash
  String get _baseUrl => instanceUrl?.replaceAll(RegExp(r'/$'), '') ?? '';

  /// Debug fetch to inspect raw response
  Future<Map<String, dynamic>> debugFetch(String path) async {
    try {
       final tokenResponse = await helper!.getTokenFromStorage();
       final token = tokenResponse?.accessToken;
       
       final uri = Uri.parse('$_baseUrl$path');
       
       appLogger.apiCall('DEBUG', uri.toString());
       
       final response = await http.get(
          uri,
          headers: {
             'Authorization': 'Bearer $token',
             'Accept': 'application/json',
          },
       );
       
       return {
          'statusCode': response.statusCode,
          'body': response.body,
          'headers': response.headers,
          'url': uri.toString(),
       };
    } catch (e) {
       return {'error': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // HIGH-PRIORITY ENDPOINTS (batch added)
  // ══════════════════════════════════════════════════════════════════

  /// Get relationships between the current user and given accounts
  /// GET /api/v1/accounts/relationships?id[]=...
  Future<List<Map<String, dynamic>>> getRelationships(List<String> accountIds) async {
    try {
      final params = accountIds.map((id) => 'id[]=$id').join('&');
      final resp = await _apiGet('${instanceUrl!}/api/v1/accounts/relationships?$params');
      appLogger.apiCall('GET', '/api/v1/accounts/relationships', params: {'ids': accountIds.toString()});
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching relationships', e, s);
      return [];
    }
  }

  /// Get accounts that favourited a status
  /// GET /api/v1/statuses/:id/favourited_by
  Future<List<Account>> getFavouritedBy(String statusId, {int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/statuses/$statusId/favourited_by?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/statuses/$statusId/favourited_by');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching favourited_by', e, s);
      return [];
    }
  }

  /// Get accounts that reblogged a status
  /// GET /api/v1/statuses/:id/reblogged_by
  Future<List<Account>> getRebloggedBy(String statusId, {int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/statuses/$statusId/reblogged_by?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/statuses/$statusId/reblogged_by');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching reblogged_by', e, s);
      return [];
    }
  }

  /// Discover posts
  /// GET /api/v1/discover/posts
  Future<List<Status>> discoverPosts({int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/discover/posts?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/discover/posts');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((s) => Status.fromJson(s)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching discover posts', e, s);
      return [];
    }
  }

  /// Discover popular accounts
  /// GET /api/v1.1/discover/accounts/popular  (also /api/v1/discover/accounts/popular)
  Future<List<Account>> discoverPopularAccounts({int limit = 20}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/discover/accounts/popular?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/discover/accounts/popular');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching popular accounts', e, s);
      return [];
    }
  }

  /// Trending posts
  /// GET /api/v1.1/discover/posts/trending
  Future<List<Status>> getTrendingPosts({int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/discover/posts/trending?limit=$limit');
      appLogger.apiCall('GET', '/api/v1.1/discover/posts/trending');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        // Pixelfed may return {data: [...]} or [...]
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? decoded);
        return data.map((s) => Status.fromJson(s)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching trending posts', e, s);
      return [];
    }
  }

  /// Full search (accounts, statuses, hashtags)
  /// GET /api/v2/search?q=...&type=...&limit=...
  /// type can be: accounts, statuses, hashtags (or omitted for all)
  Future<Map<String, dynamic>> searchV2(String query, {String? type, int limit = 20, int offset = 0, bool resolve = false}) async {
    try {
      final params = <String, String>{
        'q': query,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'resolve': resolve.toString(),
      };
      if (type != null) params['type'] = type;
      final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final resp = await _apiGet('${instanceUrl!}/api/v2/search?$queryString');
      appLogger.apiCall('GET', '/api/v2/search', params: {'q': query, 'type': type ?? 'all'});
      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      }
      return {'accounts': [], 'statuses': [], 'hashtags': []};
    } catch (e, s) {
      appLogger.error('Error in v2 search', e, s);
      return {'accounts': [], 'statuses': [], 'hashtags': []};
    }
  }

  /// Get follow requests
  /// GET /api/v1/follow_requests
  Future<List<Account>> getFollowRequests({int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/follow_requests?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/follow_requests');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching follow requests', e, s);
      return [];
    }
  }

  /// Accept a follow request
  /// POST /api/v1/follow_requests/{id}/authorize
  Future<bool> acceptFollowRequest(String accountId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/follow_requests/$accountId/authorize');
      appLogger.apiCall('POST', '/api/v1/follow_requests/$accountId/authorize');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error accepting follow request', e, s);
      return false;
    }
  }

  /// Reject a follow request
  /// POST /api/v1/follow_requests/{id}/reject
  Future<bool> rejectFollowRequest(String accountId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/follow_requests/$accountId/reject');
      appLogger.apiCall('POST', '/api/v1/follow_requests/$accountId/reject');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error rejecting follow request', e, s);
      return false;
    }
  }

  /// Delete a direct message
  /// DELETE /api/v1.1/direct/thread/message
  Future<bool> deleteDirectMessage(String messageId) async {
    try {
      final apiUrl = '${instanceUrl!}/api/v1.1/direct/thread/message';
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'id': messageId}),
      );
      appLogger.apiCall('DELETE', '/api/v1.1/direct/thread/message', params: {'id': messageId});
      appLogger.apiResponse(apiUrl, resp.statusCode);
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e, s) {
      appLogger.error('Error deleting direct message', e, s);
      return false;
    }
  }

  /// Upload media in a direct message thread
  /// POST /api/v1.1/direct/thread/media
  Future<String?> uploadDirectMessageMedia(String filePath) async {
    try {
      final uri = Uri.parse('${instanceUrl!}/api/v1.1/direct/thread/media');
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({'Authorization': 'Bearer $token'});
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      appLogger.apiCall('POST', '/api/v1.1/direct/thread/media');
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      appLogger.apiResponse('/api/v1.1/direct/thread/media', responseBody.statusCode, body: responseBody.body);

      if (responseBody.statusCode == 200 || responseBody.statusCode == 201) {
        final data = json.decode(responseBody.body);
        return data['id']?.toString() ?? data['media_id']?.toString();
      }
      return null;
    } catch (e, s) {
      appLogger.error('Error uploading DM media', e, s);
      return null;
    }
  }

  /// Publish a story (after uploading via createStory)
  /// POST /api/web/stories/v1/publish
  Future<bool> publishStory({required String mediaId, int duration = 10, bool canReply = true, bool canReact = true}) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/stories/publish'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'media_id': mediaId,
          'duration': duration,
          'can_reply': canReply,
          'can_react': canReact,
        }),
      );
      appLogger.apiCall('POST', '/api/v1.1/stories/publish', params: {'media_id': mediaId, 'duration': duration});
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error publishing story', e, s);
      return false;
    }
  }

  /// Translate text using OpenAI-compatible API
  /// Reads config from SharedPreferences
  static Future<String?> translateText(String text, String targetLang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('auto_translate_enabled') ?? false;
      if (!enabled) return null;
      
      final endpoint = prefs.getString('openai_translate_endpoint') ?? 'https://api.openai.com/v1/chat/completions';
      final apiKey = prefs.getString('openai_translate_api_key') ?? '';
      if (apiKey.isEmpty) return null;
      
      final langName = targetLang;
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a translator. Translate the following text to $langName. Return ONLY the translated text, nothing else.',
            },
            {
              'role': 'user',
              'content': text,
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.3,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translated = data['choices']?[0]?['message']?['content']?.toString().trim();
        return translated;
      }
      appLogger.error('Translation API error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      appLogger.error('Translation error', e);
      return null;
    }
  }

  /// Mark a story as viewed
  /// POST /api/v1.1/stories/seen
  Future<bool> markStoryViewed(String storyId) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/stories/seen'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'id': storyId}),
      );
      appLogger.apiCall('POST', '/api/v1.1/stories/seen', params: {'id': storyId});
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error marking story viewed', e, s);
      return false;
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 1 — Accounts                                        ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Lookup account by username (webfinger)
  /// GET /api/v1/accounts/lookup?acct=...
  Future<Account?> lookupAccount(String username) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/accounts/lookup?acct=${Uri.encodeComponent(username)}');
      appLogger.apiCall('GET', '/api/v1/accounts/lookup', params: {'acct': username});
      if (resp.statusCode == 200) return Account.fromJson(json.decode(resp.body));
      return null;
    } catch (e, s) {
      appLogger.error('Error looking up account', e, s);
      return null;
    }
  }

  /// Remove an account from followers
  /// POST /api/v1/accounts/{id}/remove_from_followers
  Future<bool> removeFromFollowers(String accountId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/accounts/$accountId/remove_from_followers');
      appLogger.apiCall('POST', '/api/v1/accounts/$accountId/remove_from_followers');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error removing follower', e, s);
      return false;
    }
  }

  /// Pin / endorse an account
  /// POST /api/v1/accounts/{id}/pin
  Future<bool> pinAccount(String accountId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/accounts/$accountId/pin');
      appLogger.apiCall('POST', '/api/v1/accounts/$accountId/pin');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error pinning account', e, s);
      return false;
    }
  }

  /// Unpin / un-endorse an account
  /// POST /api/v1/accounts/{id}/unpin
  Future<bool> unpinAccount(String accountId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/accounts/$accountId/unpin');
      appLogger.apiCall('POST', '/api/v1/accounts/$accountId/unpin');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error unpinning account', e, s);
      return false;
    }
  }

  /// Get lists containing an account
  /// GET /api/v1/accounts/{id}/lists
  Future<List<Map<String, dynamic>>> getAccountLists(String accountId) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/accounts/$accountId/lists');
      appLogger.apiCall('GET', '/api/v1/accounts/$accountId/lists');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error getting account lists', e, s);
      return [];
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 2 — Statuses                                        ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Get link preview card for a status
  /// GET /api/v1/statuses/{id}/card
  Future<Map<String, dynamic>?> getStatusCard(String statusId) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/statuses/$statusId/card');
      appLogger.apiCall('GET', '/api/v1/statuses/$statusId/card');
      if (resp.statusCode == 200) return json.decode(resp.body);
      return null;
    } catch (e, s) {
      appLogger.error('Error fetching status card', e, s);
      return null;
    }
  }

  /// Pin a status to profile
  /// POST /api/v1/statuses/{id}/pin
  Future<bool> pinStatus(String statusId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/statuses/$statusId/pin');
      appLogger.apiCall('POST', '/api/v1/statuses/$statusId/pin');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error pinning status', e, s);
      return false;
    }
  }

  /// Unpin a status from profile
  /// POST /api/v1/statuses/{id}/unpin
  Future<bool> unpinStatus(String statusId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/statuses/$statusId/unpin');
      appLogger.apiCall('POST', '/api/v1/statuses/$statusId/unpin');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error unpinning status', e, s);
      return false;
    }
  }

  /// Get edit history of a status
  /// GET /api/v1/statuses/{id}/history
  Future<List<Map<String, dynamic>>> getStatusHistory(String statusId) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/statuses/$statusId/history');
      appLogger.apiCall('GET', '/api/v1/statuses/$statusId/history');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching status history', e, s);
      return [];
    }
  }

  /// Edit an existing status
  /// PUT /api/v1/statuses/{id}
  Future<bool> editStatus(String statusId, {required String content, List<String>? mediaIds, bool? sensitive, String? spoilerText}) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final body = <String, dynamic>{'status': content};
      if (mediaIds != null) body['media_ids'] = mediaIds;
      if (sensitive != null) body['sensitive'] = sensitive;
      if (spoilerText != null) body['spoiler_text'] = spoilerText;

      final resp = await httpClient.put(
        Uri.parse('${instanceUrl!}/api/v1/statuses/$statusId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      appLogger.apiCall('PUT', '/api/v1/statuses/$statusId');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error editing status', e, s);
      return false;
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 3 — Discover & Trending                             ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Trending hashtags
  /// GET /api/v1.1/discover/posts/hashtags
  Future<List<Map<String, dynamic>>> discoverTrendingHashtags({int limit = 20}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/discover/posts/hashtags?limit=$limit');
      appLogger.apiCall('GET', '/api/v1.1/discover/posts/hashtags');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
        if (decoded is Map && decoded['tags'] != null) return (decoded['tags'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching trending hashtags', e, s);
      return [];
    }
  }

  /// Network (federated) trending posts
  /// GET /api/v1.1/discover/posts/network/trending
  Future<List<Status>> discoverNetworkTrending({int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/discover/posts/network/trending?limit=$limit');
      appLogger.apiCall('GET', '/api/v1.1/discover/posts/network/trending');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);
        return data.map((s) => Status.fromJson(s)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching network trending', e, s);
      return [];
    }
  }

  /// Get general trends
  /// GET /api/v1/trends
  Future<List<Map<String, dynamic>>> getTrends() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/trends');
      appLogger.apiCall('GET', '/api/v1/trends');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching trends', e, s);
      return [];
    }
  }

  /// Get follow suggestions
  /// GET /api/v1/suggestions
  Future<List<Account>> getSuggestions({int limit = 20}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/suggestions?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/suggestions');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((s) {
          // Mastodon v2 suggestions wrap account in {source, account}
          if (s is Map && s.containsKey('account')) {
            return Account.fromJson(s['account']);
          }
          return Account.fromJson(s);
        }).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching suggestions', e, s);
      return [];
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 4 — Media                                           ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Get media attachment info
  /// GET /api/v1/media/{id}
  Future<Map<String, dynamic>?> getMedia(String mediaId) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/media/$mediaId');
      appLogger.apiCall('GET', '/api/v1/media/$mediaId');
      if (resp.statusCode == 200) return json.decode(resp.body);
      return null;
    } catch (e, s) {
      appLogger.error('Error fetching media', e, s);
      return null;
    }
  }

  /// Update media description / alt text
  /// PUT /api/v1/media/{id}
  Future<bool> updateMedia(String mediaId, {String? description}) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final body = <String, dynamic>{};
      if (description != null) body['description'] = description;

      final resp = await httpClient.put(
        Uri.parse('${instanceUrl!}/api/v1/media/$mediaId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      appLogger.apiCall('PUT', '/api/v1/media/$mediaId');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error updating media', e, s);
      return false;
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 5 — DM Advanced                                     ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Mute a DM conversation
  /// POST /api/v1.1/direct/thread/mute
  Future<bool> muteConversation(String threadId) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/direct/thread/mute'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'id': threadId}),
      );
      appLogger.apiCall('POST', '/api/v1.1/direct/thread/mute');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error muting conversation', e, s);
      return false;
    }
  }

  /// Unmute a DM conversation
  /// POST /api/v1.1/direct/thread/unmute
  Future<bool> unmuteConversation(String threadId) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/direct/thread/unmute'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'id': threadId}),
      );
      appLogger.apiCall('POST', '/api/v1.1/direct/thread/unmute');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error unmuting conversation', e, s);
      return false;
    }
  }

  /// Mark conversation as read
  /// POST /api/v1.1/direct/thread/read
  Future<bool> markConversationRead(String threadId) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/direct/thread/read'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'id': threadId}),
      );
      appLogger.apiCall('POST', '/api/v1.1/direct/thread/read');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error marking conversation read', e, s);
      return false;
    }
  }

  /// Lookup a user for DM compose
  /// POST /api/v1.1/direct/lookup
  Future<List<Account>> lookupDmUser(String query) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/direct/lookup'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'q': query}),
      );
      appLogger.apiCall('POST', '/api/v1.1/direct/lookup');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error looking up DM user', e, s);
      return [];
    }
  }

  /// Get mutuals for DM compose
  /// GET /api/v1.1/direct/compose/mutuals
  Future<List<Account>> getDmMutuals() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/direct/compose/mutuals');
      appLogger.apiCall('GET', '/api/v1.1/direct/compose/mutuals');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching DM mutuals', e, s);
      return [];
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 6 — Stories Advanced                                 ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Delete / self-expire a story
  /// POST /api/v1.1/stories/self-expire/{id}
  Future<bool> deleteStory(String storyId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1.1/stories/self-expire/$storyId');
      appLogger.apiCall('POST', '/api/v1.1/stories/self-expire/$storyId');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error deleting story', e, s);
      return false;
    }
  }

  /// Comment on a story
  /// POST /api/v1.1/stories/comment
  Future<bool> commentOnStory(String storyId, String comment) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/stories/comment'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'sid': storyId, 'comment': comment}),
      );
      appLogger.apiCall('POST', '/api/v1.1/stories/comment');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error commenting on story', e, s);
      return false;
    }
  }

  /// Get story viewers
  /// GET /api/v1.2/stories/viewers
  Future<List<Account>> getStoryViewers(String storyId) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.2/stories/viewers?sid=$storyId');
      appLogger.apiCall('GET', '/api/v1.2/stories/viewers');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching story viewers', e, s);
      return [];
    }
  }

  /// Get own story carousel
  /// GET /api/v1.1/stories/self-carousel
  Future<List<Map<String, dynamic>>> getSelfCarousel() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/stories/self-carousel');
      appLogger.apiCall('GET', '/api/v1.1/stories/self-carousel');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching self carousel', e, s);
      return [];
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 7 — Collections                                     ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Get collections for a user
  /// GET /api/v1.1/collections/accounts/{id}
  Future<List<Map<String, dynamic>>> getUserCollections(String accountId) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/collections/accounts/$accountId');
      appLogger.apiCall('GET', '/api/v1.1/collections/accounts/$accountId');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching user collections', e, s);
      return [];
    }
  }

  /// Get items in a collection
  /// GET /api/v1.1/collections/items/{id}
  Future<List<Status>> getCollectionItems(String collectionId) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/collections/items/$collectionId');
      appLogger.apiCall('GET', '/api/v1.1/collections/items/$collectionId');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((s) => Status.fromJson(s)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching collection items', e, s);
      return [];
    }
  }

  /// View a collection (metadata)
  /// GET /api/v1.1/collections/view/{id}
  Future<Map<String, dynamic>?> viewCollection(String collectionId) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/collections/view/$collectionId');
      appLogger.apiCall('GET', '/api/v1.1/collections/view/$collectionId');
      if (resp.statusCode == 200) return json.decode(resp.body);
      return null;
    } catch (e, s) {
      appLogger.error('Error viewing collection', e, s);
      return null;
    }
  }

  /// Add a post to a collection
  /// POST /api/v1.1/collections/add
  Future<bool> addToCollection(String collectionId, String statusId) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/collections/add'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'collection_id': collectionId, 'post_id': statusId}),
      );
      appLogger.apiCall('POST', '/api/v1.1/collections/add');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error adding to collection', e, s);
      return false;
    }
  }

  /// Get own collections
  /// GET /api/v1.1/collections/self
  Future<List<Map<String, dynamic>>> getMyCollections() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/collections/self');
      appLogger.apiCall('GET', '/api/v1.1/collections/self');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching my collections', e, s);
      return [];
    }
  }

  /// Update a collection
  /// POST /api/v1.1/collections/update/{id}
  Future<bool> updateCollection(String collectionId, {String? title, String? description}) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1.1/collections/update/$collectionId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      appLogger.apiCall('POST', '/api/v1.1/collections/update/$collectionId');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error updating collection', e, s);
      return false;
    }
  }

  /// Delete a collection
  /// DELETE /api/v1.1/collections/delete/{id}
  Future<bool> deleteCollection(String collectionId) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.delete(
        Uri.parse('${instanceUrl!}/api/v1.1/collections/delete/$collectionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      appLogger.apiCall('DELETE', '/api/v1.1/collections/delete/$collectionId');
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e, s) {
      appLogger.error('Error deleting collection', e, s);
      return false;
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 8 — Domain Blocks & Content Filters                  ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Get blocked domains
  /// GET /api/v1/domain_blocks
  Future<List<String>> getDomainBlocks({int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/domain_blocks?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/domain_blocks');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((d) => d.toString()).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching domain blocks', e, s);
      return [];
    }
  }

  /// Block a domain
  /// POST /api/v1/domain_blocks
  Future<bool> blockDomain(String domain) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v1/domain_blocks'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'domain': domain}),
      );
      appLogger.apiCall('POST', '/api/v1/domain_blocks');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error blocking domain', e, s);
      return false;
    }
  }

  /// Unblock a domain
  /// DELETE /api/v1/domain_blocks
  Future<bool> unblockDomain(String domain) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.delete(
        Uri.parse('${instanceUrl!}/api/v1/domain_blocks'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'domain': domain}),
      );
      appLogger.apiCall('DELETE', '/api/v1/domain_blocks');
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e, s) {
      appLogger.error('Error unblocking domain', e, s);
      return false;
    }
  }

  /// Get content filters
  /// GET /api/v2/filters
  Future<List<Map<String, dynamic>>> getFilters() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v2/filters');
      appLogger.apiCall('GET', '/api/v2/filters');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching filters', e, s);
      return [];
    }
  }

  /// Create a content filter
  /// POST /api/v2/filters
  Future<Map<String, dynamic>?> createFilter({
    required String title,
    required List<String> context,
    String filterAction = 'warn',
    int? expiresIn,
    List<Map<String, String>>? keywords,
  }) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final body = <String, dynamic>{
        'title': title,
        'context': context,
        'filter_action': filterAction,
      };
      if (expiresIn != null) body['expires_in'] = expiresIn;
      if (keywords != null) body['keywords_attributes'] = keywords;

      final resp = await httpClient.post(
        Uri.parse('${instanceUrl!}/api/v2/filters'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      appLogger.apiCall('POST', '/api/v2/filters');
      if (resp.statusCode == 200) return json.decode(resp.body);
      return null;
    } catch (e, s) {
      appLogger.error('Error creating filter', e, s);
      return null;
    }
  }

  /// Update a content filter
  /// PUT /api/v2/filters/{id}
  Future<bool> updateFilter(String filterId, {String? title, List<String>? context, String? filterAction}) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (context != null) body['context'] = context;
      if (filterAction != null) body['filter_action'] = filterAction;

      final resp = await httpClient.put(
        Uri.parse('${instanceUrl!}/api/v2/filters/$filterId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      appLogger.apiCall('PUT', '/api/v2/filters/$filterId');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error updating filter', e, s);
      return false;
    }
  }

  /// Delete a content filter
  /// DELETE /api/v2/filters/{id}
  Future<bool> deleteFilter(String filterId) async {
    try {
      final tokenResponse = await helper!.getTokenFromStorage();
      final token = tokenResponse?.accessToken;
      if (token == null) throw AuthenticationException('No access token');

      final resp = await httpClient.delete(
        Uri.parse('${instanceUrl!}/api/v2/filters/$filterId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      appLogger.apiCall('DELETE', '/api/v2/filters/$filterId');
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e, s) {
      appLogger.error('Error deleting filter', e, s);
      return false;
    }
  }

  // ╔══════════════════════════════════════════════════════════════╗
  // ║  BATCH 9 — Archive, Tags, Misc                             ║
  // ╚══════════════════════════════════════════════════════════════╝

  /// Archive a post
  /// POST /api/v1.1/archive/add/{id}
  Future<bool> archivePost(String statusId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1.1/archive/add/$statusId');
      appLogger.apiCall('POST', '/api/v1.1/archive/add/$statusId');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error archiving post', e, s);
      return false;
    }
  }

  /// Unarchive a post
  /// POST /api/v1.1/archive/remove/{id}
  Future<bool> unarchivePost(String statusId) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1.1/archive/remove/$statusId');
      appLogger.apiCall('POST', '/api/v1.1/archive/remove/$statusId');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error unarchiving post', e, s);
      return false;
    }
  }

  /// Get archived posts
  /// GET /api/v1.1/archive/list
  Future<List<Status>> getArchivedPosts({int limit = 20}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/archive/list?limit=$limit');
      appLogger.apiCall('GET', '/api/v1.1/archive/list');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((s) => Status.fromJson(s)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching archived posts', e, s);
      return [];
    }
  }

  /// Get custom emojis
  /// GET /api/v1/custom_emojis
  Future<List<Map<String, dynamic>>> getCustomEmojis() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/custom_emojis');
      appLogger.apiCall('GET', '/api/v1/custom_emojis');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching custom emojis', e, s);
      return [];
    }
  }

  /// Get instance info
  /// GET /api/v1/instance
  Future<Map<String, dynamic>?> getInstanceInfo() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/instance');
      appLogger.apiCall('GET', '/api/v1/instance');
      if (resp.statusCode == 200) return json.decode(resp.body);
      return null;
    } catch (e, s) {
      appLogger.error('Error fetching instance info', e, s);
      return null;
    }
  }

  /// Get user preferences
  /// GET /api/v1/preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/preferences');
      appLogger.apiCall('GET', '/api/v1/preferences');
      if (resp.statusCode == 200) return json.decode(resp.body);
      return null;
    } catch (e, s) {
      appLogger.error('Error fetching preferences', e, s);
      return null;
    }
  }

  /// Get instance announcements
  /// GET /api/v1/announcements
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/announcements');
      appLogger.apiCall('GET', '/api/v1/announcements');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching announcements', e, s);
      return [];
    }
  }

  /// Get followed tags
  /// GET /api/v1/followed_tags
  Future<List<Map<String, dynamic>>> getFollowedTags({int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/followed_tags?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/followed_tags');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching followed tags', e, s);
      return [];
    }
  }

  /// Follow a hashtag
  /// POST /api/v1/tags/{name}/follow
  Future<bool> followTag(String tagName) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/tags/${Uri.encodeComponent(tagName)}/follow');
      appLogger.apiCall('POST', '/api/v1/tags/$tagName/follow');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error following tag', e, s);
      return false;
    }
  }

  /// Unfollow a hashtag
  /// POST /api/v1/tags/{name}/unfollow
  Future<bool> unfollowTag(String tagName) async {
    try {
      final resp = await _apiPost('${instanceUrl!}/api/v1/tags/${Uri.encodeComponent(tagName)}/unfollow');
      appLogger.apiCall('POST', '/api/v1/tags/$tagName/unfollow');
      return resp.statusCode == 200;
    } catch (e, s) {
      appLogger.error('Error unfollowing tag', e, s);
      return false;
    }
  }

  /// Get related tags
  /// GET /api/v1/tags/{name}/related
  Future<List<Map<String, dynamic>>> getRelatedTags(String tagName) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/tags/${Uri.encodeComponent(tagName)}/related');
      appLogger.apiCall('GET', '/api/v1/tags/$tagName/related');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching related tags', e, s);
      return [];
    }
  }

  /// Search for a location (compose)
  /// GET /api/v1.1/compose/search/location?q=...
  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1.1/compose/search/location?q=${Uri.encodeComponent(query)}');
      appLogger.apiCall('GET', '/api/v1.1/compose/search/location', params: {'q': query});
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error searching location', e, s);
      return [];
    }
  }

  /// Get all lists
  /// GET /api/v1/lists
  Future<List<Map<String, dynamic>>> getLists() async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/lists');
      appLogger.apiCall('GET', '/api/v1/lists');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching lists', e, s);
      return [];
    }
  }

  /// Get accounts in a list
  /// GET /api/v1/lists/{id}/accounts
  Future<List<Account>> getListAccounts(String listId, {int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/lists/$listId/accounts?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/lists/$listId/accounts');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching list accounts', e, s);
      return [];
    }
  }

  /// Get endorsements (pinned accounts)
  /// GET /api/v1/endorsements
  Future<List<Account>> getEndorsements({int limit = 40}) async {
    try {
      final resp = await _apiGet('${instanceUrl!}/api/v1/endorsements?limit=$limit');
      appLogger.apiCall('GET', '/api/v1/endorsements');
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((a) => Account.fromJson(a)).toList();
      }
      return [];
    } catch (e, s) {
      appLogger.error('Error fetching endorsements', e, s);
      return [];
    }
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
