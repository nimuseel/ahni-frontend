import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/onboarding_fakes.dart';

void main() {
  testWidgets('launches the AHNI onboarding entry point', (tester) async {
    final controller = OnboardingController(
      auth: FakeAuthGateway(),
      api: FakeStudentApi(),
    );
    await tester.pumpWidget(
      AhniApp(environment: AppEnvironment.development, controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('AHNI'), findsOneWidget);
    expect(find.text('학사 준비를 이어가세요'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
