import 'dart:convert';

import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'GET /grades sends the bearer token and parses complete records',
    () async {
      final api = HttpGradeApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/grades');
          expect(request.headers['authorization'], 'Bearer jwt');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                {
                  'entityId': 'grade-id-1',
                  'course': {
                    'entityId': 'course-id-1',
                    'code': 'CSE101',
                    'name': '프로그래밍 기초',
                    'category': 'MAJOR',
                    'department': {
                      'entityId': 'department-id',
                      'name': '소프트웨어융합공학과',
                    },
                  },
                  'academicYear': 2025,
                  'term': 'SECOND',
                  'gradeCode': 'A_PLUS',
                  'gradePoint': 4.5,
                  'credit': 3.0,
                  'rpl': false,
                  'retake': true,
                  'createdAt': '2026-09-15T01:00:00Z',
                  'updatedAt': '2026-09-15T02:00:00Z',
                },
                {
                  'entityId': 'grade-id-2',
                  'course': {
                    'entityId': 'course-id-2',
                    'code': 'RPL001',
                    'name': '선행학습 인정',
                    'category': 'ELECTIVE',
                    'department': null,
                  },
                  'academicYear': 2025,
                  'term': 'FIRST',
                  'gradeCode': null,
                  'gradePoint': null,
                  'credit': 2,
                  'rpl': true,
                  'retake': false,
                  'createdAt': '2026-09-14T01:00:00Z',
                  'updatedAt': '2026-09-14T01:00:00Z',
                },
              ]),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final records = await api.getGrades('jwt');

      expect(records, hasLength(2));
      expect(records.first.course.name, '프로그래밍 기초');
      expect(records.first.course.department?.name, '소프트웨어융합공학과');
      expect(records.first.term, AcademicTerm.second);
      expect(records.first.gradeCode, GradeCode.aPlus);
      expect(records.first.gradePoint, 4.5);
      expect(records.first.credit, 3.0);
      expect(records.first.retake, isTrue);
      expect(records.last.course.department, isNull);
      expect(records.last.gradeCode, isNull);
      expect(records.last.gradePoint, isNull);
      expect(records.last.rpl, isTrue);
    },
  );

  test('malformed grade responses become a safe recoverable failure', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {'entityId': 'grade-id'},
          ]),
          200,
        ),
      ),
    );

    expect(
      () => api.getGrades('jwt'),
      throwsA(
        isA<GradeApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              GradeApiFailureKind.recoverable,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '성적 정보를 확인하지 못했습니다. 다시 시도해 주세요.',
            ),
      ),
    );
  });

  test('expired authentication uses a stable sign-in message', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    expect(
      () => api.getGrades('expired-jwt'),
      throwsA(
        isA<GradeApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              GradeApiFailureKind.unauthorized,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '로그인이 만료되었습니다. 다시 로그인해 주세요.',
            ),
      ),
    );
  });
}
