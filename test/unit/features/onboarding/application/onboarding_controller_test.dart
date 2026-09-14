import 'dart:async';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/core/network/student_api.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/onboarding_fakes.dart';

void main() {
  test('a restored session loads the student profile', () async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final api = FakeStudentApi()
      ..getProfileHandler = (token) async {
        expect(token, 'test-jwt');
        return testProfile;
      };
    final controller = OnboardingController(auth: auth, api: api);

    await controller.initialize();

    expect(controller.state, isA<ProfileReady>());
    expect((controller.state as ProfileReady).profile, testProfile);
  });

  test('STUDENT_NOT_FOUND loads departments for registration', () async {
    final api = FakeStudentApi();
    api.getProfileHandler = (_) => Future.error(
      const StudentApiFailure(
        StudentApiFailureKind.studentNotFound,
        '학생 정보를 등록해 주세요.',
      ),
    );
    api.getDepartmentsHandler = () async => const [testDepartment];
    final controller = OnboardingController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await controller.initialize();

    final state = controller.state as RegistrationRequired;
    expect(state.departments, const [testDepartment]);
  });

  test('401 signs out and returns to authentication', () async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final api = FakeStudentApi()
      ..getProfileHandler = (_) => Future.error(
        const StudentApiFailure(
          StudentApiFailureKind.unauthorized,
          '로그인이 만료되었습니다.',
        ),
      );
    final controller = OnboardingController(auth: auth, api: api);

    await controller.initialize();

    expect(auth.signOutCalls, 1);
    expect(controller.state, isA<AuthenticationRequired>());
  });

  test('sign-up without a session waits for email verification', () async {
    final controller = OnboardingController(
      auth: FakeAuthGateway(),
      api: FakeStudentApi(),
    );

    await controller.signUp('  student@inha.edu  ', 'password123');

    final state = controller.state as EmailVerificationPending;
    expect(state.email, 'student@inha.edu');
  });

  test('confirmed session continues student onboarding', () async {
    final auth = FakeAuthGateway();
    final api = FakeStudentApi();
    api.getProfileHandler = (_) => Future.error(
      const StudentApiFailure(
        StudentApiFailureKind.studentNotFound,
        '학생 정보를 등록해 주세요.',
      ),
    );
    api.getDepartmentsHandler = () async => const [testDepartment];
    final controller = OnboardingController(auth: auth, api: api);
    addTearDown(controller.dispose);
    addTearDown(auth.dispose);

    await controller.initialize();
    await controller.signUp('student@inha.edu', 'password123');
    auth.emitSignedIn(testSession);
    await pumpEventQueue();

    expect(controller.state, isA<RegistrationRequired>());
  });

  test(
    'resending confirmation keeps the pending email and shows success',
    () async {
      final auth = FakeAuthGateway();
      final controller = OnboardingController(
        auth: auth,
        api: FakeStudentApi(),
      );
      addTearDown(controller.dispose);
      addTearDown(auth.dispose);

      await controller.signUp('student@inha.edu', 'password123');
      await controller.resendConfirmation();

      final state = controller.state as EmailVerificationPending;
      expect(auth.lastResendEmail, 'student@inha.edu');
      expect(state.email, 'student@inha.edu');
      expect(state.message, '인증 메일을 다시 보냈어요.');
    },
  );

  test(
    'resend failure keeps the pending email and shows safe feedback',
    () async {
      final auth = FakeAuthGateway()
        ..resendError = const AuthFailure('요청이 많습니다. 잠시 후 다시 시도해 주세요.');
      final controller = OnboardingController(
        auth: auth,
        api: FakeStudentApi(),
      );
      addTearDown(controller.dispose);
      addTearDown(auth.dispose);

      await controller.signUp('student@inha.edu', 'password123');
      await controller.resendConfirmation();

      final state = controller.state as EmailVerificationPending;
      expect(state.email, 'student@inha.edu');
      expect(state.message, '요청이 많습니다. 잠시 후 다시 시도해 주세요.');
      expect(state.isError, isTrue);
    },
  );

  test(
    'resend completion does not restore a pending screen after leaving',
    () async {
      final result = Completer<void>();
      final auth = FakeAuthGateway()..resendHandler = (_) => result.future;
      final controller = OnboardingController(
        auth: auth,
        api: FakeStudentApi(),
      );
      addTearDown(controller.dispose);
      addTearDown(auth.dispose);

      await controller.signUp('student@inha.edu', 'password123');
      final resend = controller.resendConfirmation();
      controller.returnToAuthentication();
      result.complete();
      await resend;

      expect(controller.state, isA<AuthenticationRequired>());
    },
  );

  test(
    'password reset request normalizes the email and shows generic success',
    () async {
      final auth = FakeAuthGateway();
      final controller = OnboardingController(
        auth: auth,
        api: FakeStudentApi(),
      );
      addTearDown(controller.dispose);
      addTearDown(auth.dispose);

      await controller.requestPasswordReset('  STUDENT@INHA.EDU  ');

      final state = controller.state as AuthenticationRequired;
      expect(auth.lastPasswordResetEmail, 'student@inha.edu');
      expect(state.message, '비밀번호 재설정 메일을 보냈어요. 메일함을 확인해 주세요.');
      expect(state.isError, isFalse);
    },
  );

  test('password recovery link opens the new password state', () async {
    final auth = FakeAuthGateway();
    final controller = OnboardingController(auth: auth, api: FakeStudentApi());
    addTearDown(controller.dispose);
    addTearDown(auth.dispose);
    await controller.initialize();

    auth.emitPasswordRecovery(testSession);
    await pumpEventQueue();

    expect(controller.state, isA<PasswordRecoveryRequired>());
  });

  test('updating the password signs out and returns to login', () async {
    final auth = FakeAuthGateway();
    final controller = OnboardingController(auth: auth, api: FakeStudentApi());
    addTearDown(controller.dispose);
    addTearDown(auth.dispose);
    await controller.initialize();
    auth.emitPasswordRecovery(testSession);
    await pumpEventQueue();

    await controller.updatePassword('new-password');

    final state = controller.state as AuthenticationRequired;
    expect(auth.lastUpdatedPassword, 'new-password');
    expect(auth.signOutCalls, 1);
    expect(state.message, '비밀번호를 변경했어요. 새 비밀번호로 로그인해 주세요.');
  });

  test(
    'password update failure stays on recovery with safe feedback',
    () async {
      final auth = FakeAuthGateway()
        ..updatePasswordError = const AuthFailure('비밀번호를 더 길고 안전하게 입력해 주세요.');
      final controller = OnboardingController(
        auth: auth,
        api: FakeStudentApi(),
      );
      addTearDown(controller.dispose);
      addTearDown(auth.dispose);
      await controller.initialize();
      auth.emitPasswordRecovery(testSession);
      await pumpEventQueue();

      await controller.updatePassword('short');

      final state = controller.state as PasswordRecoveryRequired;
      expect(state.message, '비밀번호를 더 길고 안전하게 입력해 주세요.');
      expect(state.isError, isTrue);
      expect(auth.signOutCalls, 0);
    },
  );

  test('a recoverable profile failure can retry successfully', () async {
    var requests = 0;
    final api = FakeStudentApi()
      ..getProfileHandler = (_) async {
        requests++;
        if (requests == 1) {
          throw const StudentApiFailure(
            StudentApiFailureKind.recoverable,
            '학생 정보를 불러오지 못했습니다. 다시 시도해 주세요.',
          );
        }
        return testProfile;
      };
    final controller = OnboardingController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await controller.initialize();
    expect(controller.state, isA<RetryableFailure>());

    await controller.retry();
    expect(controller.state, isA<ProfileReady>());
    expect(requests, 2);
  });

  test('registration success enters the profile state', () async {
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
    await controller.initialize();

    await controller.registerProfile(
      const StudentRegistration(
        primaryDepartmentEntityId: '00000000-0000-0000-0000-000000000001',
        admissionYear: 2024,
        enrollmentStatus: 'ENROLLED',
        nickname: '인하',
      ),
    );

    expect(api.lastRegistration?.nickname, '인하');
    expect(controller.state, isA<ProfileReady>());
  });

  test('profile loading is observable before the request completes', () async {
    final result = Completer<StudentProfile>();
    final api = FakeStudentApi()..getProfileHandler = (_) => result.future;
    final controller = OnboardingController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    final initialization = controller.initialize();

    expect(controller.state, isA<ProfileLoading>());
    result.complete(testProfile);
    await initialization;
  });
}
