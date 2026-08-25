import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launches the AHNI app shell', (tester) async {
    await tester.pumpWidget(
      const AhniApp(environment: AppEnvironment.development),
    );

    expect(find.text('AHNI'), findsOneWidget);
    expect(find.text('개발 환경이 준비되었습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
