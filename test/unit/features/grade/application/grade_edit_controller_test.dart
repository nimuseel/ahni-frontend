import 'dart:async';

import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_summary.dart';
import 'package:ahni_mobile/features/grade/domain/grade_update.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/grade_fakes.dart';
import '../../../../support/onboarding_fakes.dart';

void main() {
  test('updates a grade with the current session', () async {
    final api = _FakeGradeApi();
    final controller = GradeEditController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await controller.update('grade-id-1', _update);

    expect(api.lastAccessToken, 'test-jwt');
    expect(api.lastGradeEntityId, 'grade-id-1');
    expect(api.lastUpdate, same(_update));
    expect(
      controller.state,
      isA<GradeEditSaved>().having((state) => state.grade, 'grade', testGrade),
    );
  });

  test('deletes a grade with the current session', () async {
    final api = _FakeGradeApi();
    final controller = GradeEditController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await controller.delete('grade-id-1');

    expect(api.lastGradeEntityId, 'grade-id-1');
    expect(api.deleteCalls, 1);
    expect(controller.state, isA<GradeEditDeleted>());
  });

  test('keeps safe feedback after a rejected update', () async {
    final api = _FakeGradeApi()
      ..error = const GradeApiFailure(
        GradeApiFailureKind.conflict,
        '이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.',
      );
    final controller = GradeEditController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await controller.update('grade-id-1', _update);

    expect(
      controller.state,
      isA<GradeEditFailure>().having(
        (state) => state.message,
        'message',
        '이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.',
      ),
    );
  });

  test('missing sessions require authentication without mutating', () async {
    final api = _FakeGradeApi();
    final controller = GradeEditController(auth: FakeAuthGateway(), api: api);

    await controller.update('grade-id-1', _update);

    expect(controller.state, isA<GradeEditAuthenticationRequired>());
    expect(api.updateCalls, 0);
    expect(api.deleteCalls, 0);
  });

  test('ignores another mutation while an update is running', () async {
    final pending = Completer<GradeRecord>();
    final api = _FakeGradeApi()..updateHandler = (_, _, _) => pending.future;
    final controller = GradeEditController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    final update = controller.update('grade-id-1', _update);
    final deletion = controller.delete('grade-id-1');

    expect(controller.state, isA<GradeEditSaving>());
    expect(api.updateCalls, 1);
    expect(api.deleteCalls, 0);

    pending.complete(testGrade);
    await Future.wait([update, deletion]);
    expect(controller.state, isA<GradeEditSaved>());
  });
}

class _FakeGradeApi implements GradeApi {
  Object? error;
  Future<GradeRecord> Function(String, String, GradeUpdate)? updateHandler;
  String? lastAccessToken;
  String? lastGradeEntityId;
  GradeUpdate? lastUpdate;
  int updateCalls = 0;
  int deleteCalls = 0;

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
  ) async => testGrade;

  @override
  Future<GradeRecord> updateGrade(
    String accessToken,
    String gradeEntityId,
    GradeUpdate update,
  ) async {
    updateCalls++;
    lastAccessToken = accessToken;
    lastGradeEntityId = gradeEntityId;
    lastUpdate = update;
    if (error case final value?) throw value;
    if (updateHandler case final value?) {
      return value(accessToken, gradeEntityId, update);
    }
    return testGrade;
  }

  @override
  Future<void> deleteGrade(String accessToken, String gradeEntityId) async {
    deleteCalls++;
    lastAccessToken = accessToken;
    lastGradeEntityId = gradeEntityId;
    if (error case final value?) throw value;
  }
}

const _update = GradeUpdate(
  academicYear: 2024,
  term: AcademicTerm.winter,
  gradeCode: GradeCode.bPlus,
  credit: 2,
  rpl: false,
  replacedGradeEntityId: 'grade-id-0',
);
