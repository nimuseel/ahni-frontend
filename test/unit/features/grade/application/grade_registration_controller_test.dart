import 'dart:async';

import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_summary.dart';
import 'package:ahni_mobile/features/grade/domain/grade_update.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/grade_fakes.dart';
import '../../../../support/onboarding_fakes.dart';

void main() {
  test('submits a registration with the current session', () async {
    final api = _FakeGradeApi()..registerResult = testGrade;
    final controller = GradeRegistrationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await controller.submit(_registration);

    expect(api.lastAccessToken, 'test-jwt');
    expect(api.lastRegistration, same(_registration));
    expect(
      controller.state,
      isA<GradeRegistrationSuccess>().having(
        (state) => state.grade,
        'grade',
        testGrade,
      ),
    );
  });

  test(
    'keeps safe validation feedback after a rejected registration',
    () async {
      final api = _FakeGradeApi()
        ..registerError = const GradeApiFailure(
          GradeApiFailureKind.conflict,
          '이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.',
        );
      final controller = GradeRegistrationController(
        auth: FakeAuthGateway(currentSession: testSession),
        api: api,
      );

      await controller.submit(_registration);

      expect(
        controller.state,
        isA<GradeRegistrationFailure>().having(
          (state) => state.message,
          'message',
          '이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.',
        ),
      );
    },
  );

  test('missing sessions require authentication without submitting', () async {
    final api = _FakeGradeApi();
    final controller = GradeRegistrationController(
      auth: FakeAuthGateway(),
      api: api,
    );

    await controller.submit(_registration);

    expect(controller.state, isA<GradeRegistrationAuthenticationRequired>());
    expect(api.registerCalls, 0);
  });

  test('ignores repeated submit while a request is running', () async {
    final pending = Completer<GradeRecord>();
    final api = _FakeGradeApi()..registerHandler = (_, _) => pending.future;
    final controller = GradeRegistrationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    final first = controller.submit(_registration);
    final second = controller.submit(_registration);
    expect(controller.state, isA<GradeRegistrationSubmitting>());
    expect(api.registerCalls, 1);

    pending.complete(testGrade);
    await Future.wait([first, second]);
    expect(controller.state, isA<GradeRegistrationSuccess>());
  });
}

class _FakeGradeApi implements GradeApi {
  GradeRecord? registerResult;
  Object? registerError;
  Future<GradeRecord> Function(
    String accessToken,
    GradeRegistration registration,
  )?
  registerHandler;
  String? lastAccessToken;
  GradeRegistration? lastRegistration;
  int registerCalls = 0;

  @override
  Future<List<GradeRecord>> getGrades(String accessToken) async => const [];

  @override
  Future<GradeSummary> getSummary(String accessToken) async =>
      const GradeSummary(
        gpa: 0,
        completedCredits: 0,
        gpaCredits: 0,
        categories: [],
      );

  @override
  Future<GradeRecord> registerGrade(
    String accessToken,
    GradeRegistration registration,
  ) async {
    registerCalls++;
    lastAccessToken = accessToken;
    lastRegistration = registration;
    if (registerError case final value?) throw value;
    if (registerHandler case final value?) {
      return value(accessToken, registration);
    }
    return registerResult!;
  }

  @override
  Future<GradeRecord> updateGrade(
    String accessToken,
    String gradeEntityId,
    GradeUpdate update,
  ) async => testGrade;

  @override
  Future<void> deleteGrade(String accessToken, String gradeEntityId) async {}
}

const _registration = GradeRegistration(
  courseEntityId: 'course-id-1',
  academicYear: 2025,
  term: AcademicTerm.second,
  gradeCode: GradeCode.aPlus,
  credit: 3,
  rpl: false,
  replacedGradeEntityId: null,
);
