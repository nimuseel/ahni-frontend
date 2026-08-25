import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses supported deployment environments', () {
    expect(AppEnvironment.parse('development'), AppEnvironment.development);
    expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    expect(AppEnvironment.parse('production'), AppEnvironment.production);
  });

  test('rejects unknown deployment environments', () {
    expect(() => AppEnvironment.parse('local'), throwsArgumentError);
  });
}
