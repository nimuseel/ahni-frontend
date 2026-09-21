import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pins the AHNI v1 backend contract', () {
    final contract = jsonDecode(
      File('contracts/backend-openapi.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final info = contract['info']! as Map<String, Object?>;

    expect(contract['openapi'], isA<String>());
    expect(contract['openapi']! as String, startsWith('3.'));
    expect(info['title'], 'AHNI API');
    expect(info['version'], 'v1');

    final paths = contract['paths']! as Map<String, Object?>;
    expect(paths, contains('/api/v1/students/me'));
    expect(paths, contains('/api/v1/students/me/majors'));
    expect(paths, contains('/api/v1/departments'));
    expect(paths, contains('/api/v1/grades'));
    expect(paths, contains('/api/v1/grades/summary'));
    expect(paths, contains('/api/v1/grades/{gradeEntityId}'));

    final components = contract['components']! as Map<String, Object?>;
    final schemas = components['schemas']! as Map<String, Object?>;
    final registration =
        schemas['StudentProfileRegistrationRequest']! as Map<String, Object?>;
    final registrationProperties =
        registration['properties']! as Map<String, Object?>;
    expect(registrationProperties, contains('doubleMajorDepartmentEntityId'));
    expect(registrationProperties, contains('minorDepartmentEntityId'));

    final profile = schemas['StudentProfileResponse']! as Map<String, Object?>;
    final profileProperties = profile['properties']! as Map<String, Object?>;
    expect(profileProperties, contains('doubleMajorDepartment'));
    expect(profileProperties, contains('minorDepartment'));

    final grade = schemas['GradeResponse']! as Map<String, Object?>;
    final gradeProperties = grade['properties']! as Map<String, Object?>;
    expect(gradeProperties, contains('course'));
    expect(gradeProperties, contains('academicYear'));
    expect(gradeProperties, contains('term'));
    expect(gradeProperties, contains('gradeCode'));
    expect(gradeProperties, contains('gradePoint'));
    expect(gradeProperties, contains('credit'));
    expect(gradeProperties, contains('rpl'));
    expect(gradeProperties, contains('replacedGradeEntityId'));

    final summary = schemas['GradeSummaryResponse']! as Map<String, Object?>;
    final summaryProperties = summary['properties']! as Map<String, Object?>;
    expect(summaryProperties, contains('gpa'));
    expect(summaryProperties, contains('completedCredits'));
    expect(summaryProperties, contains('gpaCredits'));
    expect(summaryProperties, contains('categories'));
  });
}
