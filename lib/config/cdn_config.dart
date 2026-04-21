class CdnConfig {
  /// Example:
  /// flutter run --dart-define=CDN_BASE_URL=https://your-cdn-domain/live
  static const String cdnBaseUrl = String.fromEnvironment(
    'CDN_BASE_URL',
    defaultValue: '',
  );

  static bool get hasCdnBaseUrl => cdnBaseUrl.trim().isNotEmpty;

  static String _trimmedBase() {
    return cdnBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  static String latestUrl() => '${_trimmedBase()}/latest.json';

  static String todayUrl() => '${_trimmedBase()}/today.json';
}
