class AppEnvironment {
  const AppEnvironment._();

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8081');
  static const String apiKey = String.fromEnvironment('API_KEY', defaultValue: 'dev-secret-key');
}
