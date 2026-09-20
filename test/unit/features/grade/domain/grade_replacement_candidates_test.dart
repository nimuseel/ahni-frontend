import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_replacement_candidates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offers only an earlier unused grade for the same course', () {
    final previous = _grade(id: 'previous', academicYear: 2024);
    final currentPeriod = _grade(id: 'current-period', academicYear: 2025);
    final otherCourse = _grade(
      id: 'other-course',
      academicYear: 2024,
      courseEntityId: 'course-2',
    );

    final result = gradeReplacementCandidates(
      grades: [previous, currentPeriod, otherCourse],
      courseEntityId: 'course-1',
      academicYear: 2025,
      term: AcademicTerm.first,
    );

    expect(result, [previous]);
  });

  test('keeps the replacement owned by the grade being edited', () {
    final previous = _grade(id: 'previous', academicYear: 2024);
    final current = _grade(
      id: 'current',
      academicYear: 2025,
      replacedGradeEntityId: previous.entityId,
    );

    final result = gradeReplacementCandidates(
      grades: [current, previous],
      courseEntityId: 'course-1',
      academicYear: 2025,
      term: AcademicTerm.first,
      currentGradeEntityId: current.entityId,
    );

    expect(result, [previous]);
  });
}

GradeRecord _grade({
  required String id,
  required int academicYear,
  String courseEntityId = 'course-1',
  String? replacedGradeEntityId,
}) {
  return GradeRecord(
    entityId: id,
    course: GradeCourse(
      entityId: courseEntityId,
      code: 'CSE101',
      name: '프로그래밍 기초',
      category: CourseCategory.major,
    ),
    academicYear: academicYear,
    term: AcademicTerm.first,
    gradeCode: GradeCode.bZero,
    gradePoint: 3,
    credit: 3,
    rpl: false,
    replacedGradeEntityId: replacedGradeEntityId,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
