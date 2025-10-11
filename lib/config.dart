class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081/api',
  );
  static const refreshSkewSeconds = 30;
}
