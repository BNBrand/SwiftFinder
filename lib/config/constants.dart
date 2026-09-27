class AppConstants {
  static const appName = 'SwiftFinder';

  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const authTokenKey = 'auth_token';
  static const maxItemImages = 6;
  static const maxImageSizeMb = 5;
  static const maxClaimFileSizeMb = 10;
  static const authUserKey = 'auth_user';
}
