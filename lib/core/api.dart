// Improved error handling and logging

/// Import Flutter
///
import 'dart:convert';
import 'dart:io';

/// Import Fedispace
///
import 'package:fedispace/core/error_handler.dart';
import 'package:fedispace/core/logger.dart';
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

      for (int i = 0; i < filenames.length; i++) {
        final filename = filenames[i];
        final file = File(filename);

        if (!await file.exists()) {
          throw ValidationException('File not found: $filename');
        }

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

        if (responseBody.statusCode != 200 && responseBody.statusCode != 201) {
          ErrorHandler.handleResponse(
              responseBody.statusCode, responseBody.body);
          return null;
        }

        final responseData = ErrorHandler.parseJson(responseBody.body);
        final mediaId = responseData['id']?.toString();
        
        if (mediaId != null) {
          mediaIds.add(mediaId);
        }
      }

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
