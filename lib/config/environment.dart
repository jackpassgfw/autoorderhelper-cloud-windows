enum AppFlavor { dev, staging, prod }

class AppEnvironment {
  const AppEnvironment._(this.flavor, this.apiBaseUrl);

  final AppFlavor flavor;
  final String apiBaseUrl;

  static const dev = AppEnvironment._(
    AppFlavor.dev,
    'http://localhost:18000/api/v1',
  );

  static const staging = AppEnvironment._(
    AppFlavor.staging,
    'https://staging.autoorderhelper.evergreenhealthlife.com/api/v1',
  );

  static const prod = AppEnvironment._(
    AppFlavor.prod,
    'https://autoorderhelper.evergreenhealthlife.com/api/v1',
  );

  static AppEnvironment resolve() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

    switch (env.toLowerCase()) {
      case 'prod':
        return prod;
      case 'staging':
        return staging;
      default:
        return dev;
    }
  }

  bool get isProd => flavor == AppFlavor.prod;
  bool get isStaging => flavor == AppFlavor.staging;
  bool get isDev => flavor == AppFlavor.dev;

  String get label => flavor.name.toUpperCase();
}
