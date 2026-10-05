import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';
import 'package:ahni_mobile/features/graduation/presentation/graduation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';

import '../support/graduation_fakes.dart';
import '../support/onboarding_fakes.dart';
import '../unit/graduation/graduation_test.dart' show policy, progress;

void main() {
  testWidgets('shows progress and sources at narrow width with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GraduationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: FakeGraduationApi()
        ..results = [GraduationOverview.fromJson(policy(), progress())],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: GraduationPage(
            controller: controller,
            onAuthenticationRequired: () {},
            bottomNavigationBar: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 / 30학점'), findsNWidgets(3));
    final source = find.byWidgetPredicate(
      (widget) =>
          widget is WhitespaceWrappedText && widget.data == '기준 출처: 학과 안내',
    );
    await tester.scrollUntilVisible(source, 150);
    expect(source, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing policies allow retry without hiding navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GraduationPage(
          controller: buildTestGraduationController(),
          onAuthenticationRequired: () {},
          bottomNavigationBar: const Text('탭 이동'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is WhitespaceWrappedText && widget.data.startsWith('아직 등록된'),
      ),
      findsOneWidget,
    );
    expect(find.text('탭 이동'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
