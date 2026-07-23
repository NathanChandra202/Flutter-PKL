class AppEnv {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static bool get isProd => environment == 'prod';
  static bool get isDev => !isProd;
}
