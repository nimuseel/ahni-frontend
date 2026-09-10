import 'dart:convert';

import 'package:ahni_mobile/core/network/student_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const profileJson = {
    'studentEntityId': 'student-id',
    'email': 'student@inha.edu',
    'nickname': '인하',
    'primaryDepartment': {'entityId': 'department-id', 'name': '소프트웨어융합공학과'},
    'admissionYear': 2024,
    'enrollmentStatus': 'ENROLLED',
    'accountStatus': 'ACTIVE',
  };

  test(
    'GET /students/me sends the bearer token and parses the profile',
    () async {
      final api = HttpStudentApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/students/me');
          expect(request.headers['authorization'], 'Bearer jwt');
          return http.Response.bytes(
            utf8.encode(jsonEncode(profileJson)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final profile = await api.getProfile('jwt');

      expect(profile.email, 'student@inha.edu');
      expect(profile.primaryDepartment.name, '소프트웨어융합공학과');
    },
  );

  test('STUDENT_NOT_FOUND is exposed as the registration transition', () async {
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'STUDENT_NOT_FOUND',
            'message': 'internal detail',
          }),
          404,
        ),
      ),
    );

    expect(
      () => api.getProfile('jwt'),
      throwsA(
        isA<StudentApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          StudentApiFailureKind.studentNotFound,
        ),
      ),
    );
  });

  test('POST /students/me sends the contract payload and parses 201', () async {
    late Map<String, Object?> requestBody;
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, Object?>;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/students/me');
        expect(request.headers['authorization'], 'Bearer jwt');
        expect(request.headers['content-type'], contains('application/json'));
        return http.Response.bytes(
          utf8.encode(jsonEncode(profileJson)),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final profile = await api.registerProfile(
      'jwt',
      const StudentRegistration(
        primaryDepartmentEntityId: 'department-id',
        admissionYear: 2024,
        enrollmentStatus: 'ENROLLED',
        nickname: '인하',
      ),
    );

    expect(requestBody, {
      'primaryDepartmentEntityId': 'department-id',
      'admissionYear': 2024,
      'enrollmentStatus': 'ENROLLED',
      'nickname': '인하',
    });
    expect(profile.studentEntityId, 'student-id');
  });

  test('stable registration errors use safe Korean copy', () async {
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'DEPARTMENT_NOT_FOUND',
            'message': 'database row was missing',
          }),
          404,
        ),
      ),
    );

    expect(
      () => api.registerProfile(
        'jwt',
        const StudentRegistration(
          primaryDepartmentEntityId: 'missing',
          admissionYear: 2024,
          enrollmentStatus: 'ENROLLED',
        ),
      ),
      throwsA(
        isA<StudentApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              StudentApiFailureKind.validation,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '학과 정보를 다시 선택해 주세요.',
            ),
      ),
    );
  });
}
