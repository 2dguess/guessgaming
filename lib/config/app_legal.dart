import 'package:url_launcher/url_launcher.dart';

class AppLegal {
  AppLegal._();

  /// Override these in release builds:
  /// --dart-define=PRIVACY_POLICY_URL=https://your-domain/privacy
  /// --dart-define=TERMS_OF_SERVICE_URL=https://your-domain/terms
  static const privacyPolicyUrl =
      String.fromEnvironment('PRIVACY_POLICY_URL', defaultValue: 'https://example.com/privacy-policy');
  static const termsOfServiceUrl =
      String.fromEnvironment('TERMS_OF_SERVICE_URL', defaultValue: 'https://example.com/terms-of-service');

  static Future<void> openPrivacyPolicy() => _launch(privacyPolicyUrl);

  static Future<void> openTermsOfService() => _launch(termsOfServiceUrl);

  static bool get hasProductionUrls =>
      !_isPlaceholder(privacyPolicyUrl) && !_isPlaceholder(termsOfServiceUrl);

  static Future<void> _launch(String urlString) async {
    if (_isPlaceholder(urlString)) return;
    final uri = Uri.parse(urlString);
    final ok = await canLaunchUrl(uri);
    if (!ok) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static bool _isPlaceholder(String url) => url.contains('example.com');
}
