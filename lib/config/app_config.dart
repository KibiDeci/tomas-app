class AppConfig {
  static const String _defaultServerUrl = 'http://127.0.0.1:8000';

  /// Base URL server backend (tanpa trailing slash, tanpa /api).
  ///
  /// Untuk build production, set dengan:
  /// `--dart-define=TOMAS_SERVER_URL=https://backend-kamu.com`
  static const String serverUrl = String.fromEnvironment(
    'TOMAS_SERVER_URL',
    defaultValue: _defaultServerUrl,
  );

  /// Full API base URL (digunakan oleh ApiService)
  static final String apiBaseUrl = '${_normalizedServerUrl(serverUrl)}/api';

  static String _normalizedServerUrl(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
