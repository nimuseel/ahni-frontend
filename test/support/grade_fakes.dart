import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_update.dart';

import 'onboarding_fakes.dart';

GradeListController buildTestGradeListController({
  AuthGateway? auth,
  List<GradeRecord> grades = const [],
}) {
  return GradeListController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: FakeGradeApi()..results = grades,
  );
}

CourseCatalogController buildTestCourseCatalogController({
  AuthGateway? auth,
  List<CourseCatalogItem> courses = const [testCourse],
}) {
  return CourseCatalogController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: FakeCourseApi()..results = courses,
  );
}

GradeRegistrationController buildTestGradeRegistrationController({
  AuthGateway? auth,
  GradeApi? api,
}) {
  return GradeRegistrationController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: api ?? FakeGradeApi(),
  );
}

GradeEditController buildTestGradeEditController({
  AuthGateway? auth,
  GradeApi? api,
}) {
  return GradeEditController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: api ?? FakeGradeApi(),
  );
}

class FakeCourseApi implements CourseApi {
  List<CourseCatalogItem> results = const [];
  Object? error;

  @override
  Future<List<CourseCatalogItem>> getCourses(String accessToken) async {
    if (error case final value?) throw value;
    return results;
  }
}

class FakeGradeApi implements GradeApi {
  List<GradeRecord> results = const [];
  Object? error;
  Future<List<GradeRecord>> Function(String accessToken)? handler;
  Future<GradeRecord> Function(
    String accessToken,
    GradeRegistration registration,
  )?
  registerHandler;
  Future<GradeRecord> Function(
    String accessToken,
    String gradeEntityId,
    GradeUpdate update,
  )?
  updateHandler;
  Future<void> Function(String accessToken, String gradeEntityId)?
  deleteHandler;
  String? lastAccessToken;
  GradeRegistration? lastRegistration;
  GradeUpdate? lastUpdate;
  String? lastGradeEntityId;
  int calls = 0;
  int registerCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

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
    registerCalls++;
    lastAccessToken = accessToken;
    lastRegistration = registration;
    if (error case final value?) throw value;
    if (registerHandler case final value?) {
      return value(accessToken, registration);
    }
    return testGrade;
  }

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
    if (deleteHandler case final value?) {
      await value(accessToken, gradeEntityId);
    }
  }
}

final testGrade = GradeRecord(
  entityId: 'grade-id-1',
  course: const GradeCourse(
    entityId: 'course-id-1',
    code: 'CSE101',
    name: '프로그래밍 기초',
    category: CourseCategory.major,
    department: GradeDepartment(entityId: 'department-id', name: '소프트웨어융합공학과'),
  ),
  academicYear: 2025,
  term: AcademicTerm.second,
  gradeCode: GradeCode.aPlus,
  gradePoint: 4.5,
  credit: 3,
  rpl: false,
  retake: true,
  createdAt: DateTime.utc(2026, 9, 15),
  updatedAt: DateTime.utc(2026, 9, 15),
);

const testCourse = CourseCatalogItem(
  entityId: 'course-id-1',
  code: 'CSE101',
  name: '프로그래밍 기초',
  credit: 3,
  category: CourseCategory.major,
  department: GradeDepartment(entityId: 'department-id', name: '소프트웨어융합공학과'),
);

final testPassGrade = GradeRecord(
  entityId: 'grade-id-2',
  course: const GradeCourse(
    entityId: 'course-id-2',
    code: 'GE201',
    name: '의사소통 영어',
    category: CourseCategory.generalEducation,
  ),
  academicYear: 2025,
  term: AcademicTerm.second,
  gradeCode: GradeCode.p,
  gradePoint: null,
  credit: 2,
  rpl: false,
  retake: false,
  createdAt: DateTime.utc(2026, 9, 14),
  updatedAt: DateTime.utc(2026, 9, 14),
);

final testRplGrade = GradeRecord(
  entityId: 'grade-id-3',
  course: const GradeCourse(
    entityId: 'course-id-3',
    code: 'RPL001',
    name: '선행학습 인정',
    category: CourseCategory.elective,
  ),
  academicYear: 2025,
  term: AcademicTerm.first,
  gradeCode: null,
  gradePoint: null,
  credit: 1,
  rpl: true,
  retake: false,
  createdAt: DateTime.utc(2026, 3, 1),
  updatedAt: DateTime.utc(2026, 3, 1),
);
