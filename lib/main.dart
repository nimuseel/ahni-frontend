import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:flutter/widgets.dart';

void main() {
  const configuredEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  runApp(AhniApp(environment: AppEnvironment.parse(configuredEnvironment)));
}
