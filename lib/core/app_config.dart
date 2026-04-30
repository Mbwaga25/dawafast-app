enum AppEnvironment { dev, prod }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.dev;

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        return 'http://localhost:8000/graphql/';
      case AppEnvironment.prod:
        return 'https://api.afyalink.com/graphql/';
    }
  }

  static String get apiKey {
    // These should ideally come from --dart-define or a .env file
    return const String.fromEnvironment(
      'API_KEY',
      defaultValue: 'AfyaLink_Secure_API_Key_2024_verfied',
    );
  }
}
