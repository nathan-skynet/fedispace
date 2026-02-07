import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';

/// Custom URI scheme used for redirection after auth
const String featherUriScheme = 'space.echelon4.fedispace';

/// URI for redirection after successful auth
const String featherRedirectUri = 'space.echelon4.fedispace://oauth-callback';

/// List of oauth scopes to be requested to Mastodon on authentication
///
const List<String> oauthScopes = ['read', 'write', 'follow','push'];

/// a Pixelfed instance's OAuth2 endpoints.
class PixelfedOAuth2Client extends OAuth2Client {
  /// URL of the Mastodon instance to perform auth with
  final String instanceUrl;

  PixelfedOAuth2Client({required this.instanceUrl})
      : super(
    authorizeUrl: '$instanceUrl/oauth/authorize',
    tokenUrl: '$instanceUrl/oauth/token',
    redirectUri: featherRedirectUri,
    customUriScheme: featherUriScheme,
  );
}

/// Returns an instance of the [OAuth2Helper] helper class that serves as a
/// bridge between the OAuth2 auth flow and requests to Mastodon's endpoint.
OAuth2Helper getOauthHelper(
    String instanceUrl,
    String oauthClientId,
    String oauthClientSecret,
    ) {
  final PixelfedOAuth2Client oauthClient = PixelfedOAuth2Client(
    instanceUrl: instanceUrl,
  );

  return OAuth2Helper(
    oauthClient,
    grantType: OAuth2Helper.authorizationCode,
    clientId: oauthClientId,
    clientSecret: oauthClientSecret,
    scopes: oauthScopes,
  );
}
