import 'dart:async';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads grades with the current authenticated session', () async {
    final api = _FakeGradeApi()..results = [_testGrade];
    final controller = GradeListController(
      auth: _FakeAuthGateway(currentSession: _testSession),
      api: api,
    );

    await controller.load();

    expect(api.lastAccessToken, 'test-jwt');
    expect(
      controller.state,
      isA<GradeListReady>().having((state) => state.grades, 'grades', [
        _testGrade,
      ]),
    );
  });

  test('an empty response becomes an explicit empty state', () async {
    final controller = GradeListController(
      auth: _FakeAuthGateway(currentSession: _testSession),
      api: _FakeGradeApi(),
    );

    await controller.load();

    expect(controller.state, isA<GradeListEmpty>());
  });

  test('retry replaces a recoverable failure with loaded grades', () async {
    final api = _FakeGradeApi()
      ..error = const GradeApiFailure(
        GradeApiFailureKind.recoverable,
        '성적 목록을 불러오지 못했습니다. 다시 시도해 주세요.',
      );
    final controller = GradeListController(
      auth: _FakeAuthGateway(currentSession: _testSession),
      api: api,
    );

    await controller.load();
    expect(
      controller.state,
      isA<GradeListFailure>().having(
        (state) => state.message,
        'message',
        '성적 목록을 불러오지 못했습니다. 다시 시도해 주세요.',
      ),
    );

    api
      ..error = null
      ..results = [_testGrade];
    await controller.retry();

    expect(controller.state, isA<GradeListReady>());
    expect(api.calls, 2);
  });

  test(
    'missing sessions require authentication without calling the API',
    () async {
      final api = _FakeGradeApi();
      final controller = GradeListController(
        auth: _FakeAuthGateway(),
        api: api,
      );

      await controller.load();

      expect(controller.state, isA<GradeListAuthenticationRequired>());
      expect(api.calls, 0);
    },
  );

  test('reset removes grades owned by the previous student', () async {
    final controller = GradeListController(
      auth: _FakeAuthGateway(currentSession: _testSession),
      api: _FakeGradeApi()..results = [_testGrade],
    );
    await controller.load();
    expect(controller.state, isA<GradeListReady>());

    controller.reset();

    expect(controller.state, isA<GradeListInitial>());
  });

  test(
    'reset ignores a previous student request that completes later',
    () async {
      final pending = Completer<List<GradeRecord>>();
      final api = _FakeGradeApi()..handler = (_) => pending.future;
      final controller = GradeListController(
        auth: _FakeAuthGateway(currentSession: _testSession),
        api: api,
      );

      final load = controller.load();
      expect(controller.state, isA<GradeListLoading>());
      controller.reset();
      pending.complete([_testGrade]);
      await load;

      expect(controller.state, isA<GradeListInitial>());
    },
  );
}

class _FakeGradeApi implements GradeApi {
  List<GradeRecord> results = const [];
  Object? error;
  Future<List<GradeRecord>> Function(String accessToken)? handler;
  String? lastAccessToken;
  int calls = 0;

  @override
  Future<List<GradeRecord>> getGrades(String accessToken) async {
    calls++;
    lastAccessToken = accessToken;
    if (error case final value?) throw value;
    if (handler case final value?) return value(accessToken);
    return results;
  }

  @override
  Future<GradeRecord> registerGrade(
    String accessToken,
    GradeRegistration registration,
  ) async {
    return _testGrade;
  }
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({this.currentSession});

  @override
  AuthSession? currentSession;

  @override
  Stream<AuthSession> get passwordRecoverySessions => const Stream.empty();

  @override
  Stream<AuthSession> get signedInSessions => const Stream.empty();

  @override
  Future<void> resendSignUpConfirmation(String email) => Future.value();

  @override
  Future<void> sendPasswordResetEmail(String email) => Future.value();

  @override
  Future<AuthSession?> signIn(String email, String password) =>
      Future.value(currentSession);

  @override
  Future<void> signOut() async {
    currentSession = null;
  }

  @override
  Future<AuthSession?> signUp(String email, String password) =>
      Future.value(currentSession);

  @override
  Future<void> updatePassword(String password) => Future.value();
}

const _testSession = AuthSession(
  accessToken: 'test-jwt',
  email: 'student@inha.edu',
);

final _testGrade = GradeRecord(
  entityId: 'grade-id',
  course: GradeCourse(
    entityId: 'course-id',
    code: 'CSE101',
    name: '프로그래밍 기초',
    category: CourseCategory.major,
  ),
  academicYear: 2025,
  term: AcademicTerm.second,
  gradeCode: GradeCode.aPlus,
  gradePoint: 4.5,
  credit: 3,
  rpl: false,
  retake: false,
  createdAt: DateTime.utc(2026, 9, 15),
  updatedAt: DateTime.utc(2026, 9, 15),
);
