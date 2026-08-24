enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String value) {
    return values.firstWhere(
      (environment) => environment.name == value,
      orElse: () => throw ArgumentError.value(value, 'value'),
    );
  }
}
