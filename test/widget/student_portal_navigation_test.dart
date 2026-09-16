import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/grade_fakes.dart';
import '../support/onboarding_fakes.dart';

void main() {
  testWidgets('authenticated students move between grades and profile', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final studentApi = FakeStudentApi()
      ..getProfileHandler = (_) async => testProfile;
    final gradeApi = FakeGradeApi()..results = [testGrade];
    final onboardingController = OnboardingController(
      auth: auth,
      api: studentApi,
    );
    final gradeController = GradeListController(auth: auth, api: gradeApi);

    await tester.pumpWidget(
      AhniApp(
        environment: AppEnvironment.development,
        controller: onboardingController,
        gradeController: gradeController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-summary')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('성적'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('grade-list-page')), findsOneWidget);
    expect(find.text('프로그래밍 기초'), findsOneWidget);

    await tester.tap(find.text('내 정보'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-summary')), findsOneWidget);
  });

  testWidgets('sign-out clears grades owned by the previous student', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final onboardingController = OnboardingController(
      auth: auth,
      api: FakeStudentApi()..getProfileHandler = (_) async => testProfile,
    );
    final gradeController = GradeListController(
      auth: auth,
      api: FakeGradeApi()..results = [testGrade],
    );

    await tester.pumpWidget(
      AhniApp(
        environment: AppEnvironment.development,
        controller: onboardingController,
        gradeController: gradeController,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('성적'));
    await tester.pumpAndSettle();
    expect(gradeController.state, isA<GradeListReady>());

    await tester.tap(find.text('내 정보'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('로그아웃'));
    await tester.pumpAndSettle();

    expect(gradeController.state, isA<GradeListInitial>());
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
  });
}
