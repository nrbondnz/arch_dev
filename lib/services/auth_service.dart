import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  /// Returns the first Cognito group the current user belongs to,
  /// or null if the user has no group assignment.
  static Future<String?> getCurrentUserGroup() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value.idToken;
      final payload = _decodeJwtPayload(idToken.raw);
      final groups = payload['cognito:groups'];
      if (groups is List && groups.isNotEmpty) {
        return groups.first as String;
      }
      return null;
    } on Exception catch (e) {
      safePrint('Error fetching user group: $e');
      return null;
    }
  }

  /// Returns the authenticated user's email address.
  static Future<String> getCurrentUserEmail() async {
    try {
      final attrs = await Amplify.Auth.fetchUserAttributes();
      final email = attrs
          .firstWhere(
            (a) => a.userAttributeKey == AuthUserAttributeKey.email,
            orElse: () => const AuthUserAttribute(
              userAttributeKey: AuthUserAttributeKey.email,
              value: 'User',
            ),
          )
          .value;
      return email;
    } on Exception catch (e) {
      safePrint('Error fetching user email: $e');
      return 'User';
    }
  }

  /// Returns a display-friendly name: the part of the email before '@'.
  static Future<String> getCurrentUserDisplayName() async {
    final email = await getCurrentUserEmail();
    return email.contains('@') ? email.split('@').first : email;
  }

  /// Returns the current user's Cognito sub (unique ID).
  static Future<String> getCurrentUserId() async {
    final user = await Amplify.Auth.getCurrentUser();
    return user.userId;
  }

  /// Decodes the payload section of a JWT token.
  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    var payload = parts[1];
    // Pad base64 if needed
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded) as Map<String, dynamic>;
  }
}
