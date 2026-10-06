import 'dart:convert';

import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_simulation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const expected = ExpectedGrade(
  category: CourseCategory.major,
  credit: 3,
  gradeCode: GradeCode.aPlus,
);

void main() {
  test(
    'simulation sends only expected grades and parses both summaries',
    () async {
      final api = HttpGradeApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/grades/simulation');
          expect(request.headers['authorization'], 'Bearer jwt');
          expect(jsonDecode(request.body), {
            'expectedGrades': [
              {'category': 'MAJOR', 'credit': 3.0, 'gradeCode': 'A_PLUS'},
            ],
          });
          return http.Response(
            jsonEncode({
              'current': summary(3, 3),
              'projected': summary(3.75, 6),
            }),
            200,
          );
        }),
      );
      final result = await api.simulateGrades('jwt', [expected]);
      expect(result.current.gpa, 3);
      expect(result.projected.gpa, 3.75);
      expect(result.projected.gpaCredits, 6);
      expect(result.projected.categories, hasLength(3));
    },
  );

  for (final (status, code, kind) in [
    (401, null, GradeApiFailureKind.unauthorized),
    (404, 'STUDENT_NOT_FOUND', GradeApiFailureKind.studentNotFound),
    (400, 'INVALID_REQUEST', GradeApiFailureKind.validation),
    (503, null, GradeApiFailureKind.recoverable),
  ]) {
    test('simulation maps $status to a safe failure', () async {
      final api = HttpGradeApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient(
          (_) async => http.Response(jsonEncode({'code': code}), status),
        ),
      );
      await expectLater(
        api.simulateGrades('jwt', [expected]),
        throwsA(
          isA<GradeApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            kind,
          ),
        ),
      );
    });
  }

  for (final body in [
    '{}',
    jsonEncode({'current': summary(3, 3), 'projected': summary(-1, 6)}),
    jsonEncode({
      'current': summary(3, 3),
      'projected': {...summary(3.75, 6), 'categories': []},
    }),
  ]) {
    test('malformed simulation result $body is recoverable', () async {
      final api = HttpGradeApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        api.simulateGrades('jwt', [expected]),
        throwsA(
          isA<GradeApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            GradeApiFailureKind.recoverable,
          ),
        ),
      );
    });
  }

  test('network failure does not expose raw transport errors', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => throw http.ClientException('sensitive transport detail'),
      ),
    );
    await expectLater(
      api.simulateGrades('jwt', [expected]),
      throwsA(
        isA<GradeApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          GradeApiFailureKind.recoverable,
        ),
      ),
    );
  });

  test('credit input rejects invalid values without rounding them', () {
    for (final input in [
      '0',
      '-1',
      '30.1',
      '1.25',
      'NaN',
      'Infinity',
      '1e1',
      '',
    ]) {
      expect(ExpectedGrade.parseCredit(input), isNull, reason: input);
    }
    expect(ExpectedGrade.parseCredit(' 0.1 '), 0.1);
    expect(ExpectedGrade.parseCredit('30'), 30);
  });
}

Map<String, Object?> summary(double gpa, double credits) => {
  'gpa': gpa,
  'completedCredits': credits,
  'gpaCredits': credits,
  'categories': [
    {
      'category': 'MAJOR',
      'gpa': gpa,
      'completedCredits': credits,
      'gpaCredits': credits,
    },
    {
      'category': 'GENERAL_EDUCATION',
      'gpa': 0,
      'completedCredits': 0,
      'gpaCredits': 0,
    },
    {'category': 'ELECTIVE', 'gpa': 0, 'completedCredits': 0, 'gpaCredits': 0},
  ],
};
