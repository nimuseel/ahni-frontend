import 'dart:async';

import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/core/network/student_api.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/onboarding_fakes.dart';
import '../support/whitespace_wrapped_text_finder.dart';

void main() {
  testWidgets('shows loading, actionable error, and retry success', (
    tester,
  ) async {
    final firstRequest = Completer<StudentProfile>();
    var requests = 0;
    final api = FakeStudentApi()
      ..getProfileHandler = (_) {
        requests++;
        return requests == 1 ? firstRequest.future : Future.value(testProfile);
      };
    final controller = OnboardingController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await tester.pumpWidget(
      AhniApp(environment: AppEnvironment.development, controller: controller),
    );
    await tester.pump();
    final loadingText = findWhitespaceWrappedText('학생 정보를 불러오는 중이에요…');
    expect(loadingText, findsOneWidget);
    expect(tester.getCenter(loadingText).dy, greaterThan(250));

    firstRequest.completeError(
      const StudentApiFailure(
        StudentApiFailureKind.recoverable,
        '학생 정보를 불러오지 못했습니다.\n다시 시도해 주세요.',
      ),
    );
    await tester.pump();
    expect(
      findWhitespaceWrappedText('학생 정보를 불러오지 못했습니다.\n다시 시도해 주세요.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('학사 준비를 이어가세요'), findsNothing);
    expect(find.byKey(const Key('profile-summary')), findsOneWidget);
    expect(find.text('소프트웨어융합공학과'), findsOneWidget);
  });

  testWidgets('validates school email and shows email confirmation pending', (
    tester,
  ) async {
    final controller = OnboardingController(
      auth: FakeAuthGateway(),
      api: FakeStudentApi(),
    );

    await tester.pumpWidget(
      AhniApp(environment: AppEnvironment.development, controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('학생 포털'), findsNothing);
    expect(findWhitespaceWrappedText('학사 준비, 함께 이어가요'), findsOneWidget);
    expect(
      findWhitespaceWrappedText('학교 이메일로 로그인하면 내 학사 정보를 편하게 확인할 수 있어요.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'student@gmail.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();
    expect(find.text('인하대학교 이메일(@inha.edu)을 입력해 주세요.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-sign-up-segment')));
    await tester.pump();
    expect(
      findWhitespaceWrappedText('학교 이메일로 가입한 뒤 학생 정보를 등록할 수 있어요.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      isEmpty,
    );
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'student@inha.edu',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'password123',
    );
    final signUpButton = find.widgetWithText(FilledButton, '계정 만들기');
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();
    expect(find.text('인하대학교 이메일(@inha.edu)을 입력해 주세요.'), findsNothing);
    expect(find.text('비밀번호를 6자 이상 입력해 주세요.'), findsNothing);
    expect(controller.state, isA<EmailVerificationPending>());
    expect(findWhitespaceWrappedText('이메일을 확인해 주세요'), findsOneWidget);
    expect(find.text('student@inha.edu'), findsOneWidget);
    expect(
      findWhitespaceWrappedText('메일의 링크를 확인한 뒤 로그인해 주세요.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, '로그인으로 돌아가기'));
    await tester.pump();

    expect(controller.state, isA<AuthenticationRequired>());
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
  });

  testWidgets('auth modes do not share credentials', (tester) async {
    final controller = OnboardingController(
      auth: FakeAuthGateway(),
      api: FakeStudentApi(),
    );

    await tester.pumpWidget(
      AhniApp(environment: AppEnvironment.development, controller: controller),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'student@inha.edu',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('auth-sign-up-segment')));
    await tester.pump();

    final fieldsAfterSignUp = tester.widgetList<EditableText>(
      find.byType(EditableText),
    );
    expect(
      fieldsAfterSignUp.every((field) => field.controller.text.isEmpty),
      isTrue,
    );

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'student@inha.edu',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('auth-sign-in-segment')));
    await tester.pump();

    final fieldsAfterSignIn = tester.widgetList<EditableText>(
      find.byType(EditableText),
    );
    expect(
      fieldsAfterSignIn.every((field) => field.controller.text.isEmpty),
      isTrue,
    );
  });

  testWidgets('registers a missing student profile', (tester) async {
    final api = FakeStudentApi();
    api.getProfileHandler = (_) => Future.error(
      const StudentApiFailure(
        StudentApiFailureKind.studentNotFound,
        '학생 정보를 등록해 주세요.',
      ),
    );
    api.getDepartmentsHandler = () async => const [testDepartment];
    api.registerProfileHandler = (_, registration) async => testProfile;
    final controller = OnboardingController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await tester.pumpWidget(
      AhniApp(environment: AppEnvironment.development, controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('프로필 설정'), findsNothing);
    expect(findWhitespaceWrappedText('학생 정보를 알려주세요'), findsOneWidget);
    expect(
      findWhitespaceWrappedText('학과, 입학연도와 학적 상태는 맞춤 학사 안내에 사용해요.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('registration-card')), findsOneWidget);
    expect(find.byKey(const Key('enrollment-status-segments')), findsOneWidget);

    await tester.tap(find.byKey(const Key('department-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('소프트웨어융합공학과').last);
    await tester.enterText(find.byKey(const Key('admission-year')), '2024');
    await tester.enterText(find.byKey(const Key('nickname')), '인하');
    final submitButton = find.widgetWithText(FilledButton, '학생 정보 등록');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(
      api.lastRegistration?.primaryDepartmentEntityId,
      testDepartment.entityId,
    );
    expect(api.lastRegistration?.enrollmentStatus, 'ENROLLED');
    expect(find.text('학사 준비를 이어가세요'), findsNothing);
    expect(find.byKey(const Key('profile-summary')), findsOneWidget);
    expect(find.byKey(const Key('student-information-card')), findsOneWidget);
  });

  testWidgets('auth form remains usable with large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = OnboardingController(
      auth: FakeAuthGateway(),
      api: FakeStudentApi(),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: AhniApp(
          environment: AppEnvironment.development,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(findWhitespaceWrappedText('학사 준비, 함께 이어가요'), findsOneWidget);
    expect(
      findWhitespaceWrappedText('학교 이메일로 로그인하면 내 학사 정보를 편하게 확인할 수 있어요.'),
      findsOneWidget,
    );
    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
