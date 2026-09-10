import 'dart:async';

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
