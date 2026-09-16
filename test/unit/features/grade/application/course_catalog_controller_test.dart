import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/onboarding_fakes.dart';

void main() {
  test('loads courses with the current authenticated session', () async {
    final api = _FakeCourseApi()..results = _courses;
    final controller = CourseCatalogController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await controller.load();

    expect(api.lastAccessToken, 'test-jwt');
    expect(
      controller.state,
      isA<CourseCatalogReady>().having(
        (state) => state.courses,
        'courses',
        _courses,
      ),
    );
  });

  test('an empty response becomes an explicit empty state', () async {
    final controller = CourseCatalogController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: _FakeCourseApi(),
    );

    await controller.load();

    expect(controller.state, isA<CourseCatalogEmpty>());
  });

  test('search matches trimmed course codes and Korean names', () async {
    final controller = CourseCatalogController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: _FakeCourseApi()..results = _courses,
    );
    await controller.load();

    controller.search(' cse ');
    expect(
      controller.state,
      isA<CourseCatalogReady>()
          .having((state) => state.query, 'query', 'cse')
          .having(
            (state) => state.courses.map((course) => course.code),
            'course codes',
            ['CSE101'],
          ),
    );

    controller.search('글쓰기');
    expect(
      controller.state,
      isA<CourseCatalogReady>().having(
        (state) => state.courses.map((course) => course.code),
        'course codes',
        ['GE101'],
      ),
    );
  });

  test('a query without matches keeps a searchable ready state', () async {
    final controller = CourseCatalogController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: _FakeCourseApi()..results = _courses,
    );
    await controller.load();

    controller.search('없는 과목');

    expect(
      controller.state,
      isA<CourseCatalogReady>()
          .having((state) => state.query, 'query', '없는 과목')
          .having((state) => state.courses, 'courses', isEmpty),
    );
  });

  test('retry replaces a recoverable failure with loaded courses', () async {
    final api = _FakeCourseApi()
      ..error = const CourseApiFailure(
        CourseApiFailureKind.recoverable,
        '과목 목록을 불러오지 못했습니다. 다시 시도해 주세요.',
      );
    final controller = CourseCatalogController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );

    await controller.load();
    expect(controller.state, isA<CourseCatalogFailure>());

    api
      ..error = null
      ..results = _courses;
    await controller.retry();

    expect(controller.state, isA<CourseCatalogReady>());
  });

  test('missing sessions require authentication without an API call', () async {
    final api = _FakeCourseApi();
    final controller = CourseCatalogController(
      auth: FakeAuthGateway(),
      api: api,
    );

    await controller.load();

    expect(controller.state, isA<CourseCatalogAuthenticationRequired>());
    expect(api.calls, 0);
  });
}

class _FakeCourseApi implements CourseApi {
  List<CourseCatalogItem> results = const [];
  Object? error;
  String? lastAccessToken;
  int calls = 0;

  @override
  Future<List<CourseCatalogItem>> getCourses(String accessToken) async {
    calls++;
    lastAccessToken = accessToken;
    if (error case final value?) throw value;
    return results;
  }
}

const _courses = [
  CourseCatalogItem(
    entityId: 'course-id-1',
    code: 'CSE101',
    name: '프로그래밍 기초',
    credit: 3,
    category: CourseCategory.major,
    department: GradeDepartment(entityId: 'department-id', name: '소프트웨어융합공학과'),
  ),
  CourseCatalogItem(
    entityId: 'course-id-2',
    code: 'GE101',
    name: '대학 글쓰기',
    credit: 2,
    category: CourseCategory.generalEducation,
  ),
];
