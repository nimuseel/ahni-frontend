// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class Department {
  const Department({required this.entityId, required this.name});

  factory Department.fromJson(Map<String, Object?> json) {
    return Department(
      entityId: json['entityId']! as String,
      name: json['name']! as String,
    );
  }

  final String entityId;
  final String name;
}

class StudentProfile {
  const StudentProfile({
    required this.studentEntityId,
    required this.email,
    required this.nickname,
    required this.primaryDepartment,
    required this.admissionYear,
    required this.enrollmentStatus,
    required this.accountStatus,
  });

  factory StudentProfile.fromJson(Map<String, Object?> json) {
    return StudentProfile(
      studentEntityId: json['studentEntityId']! as String,
      email: json['email']! as String,
      nickname: json['nickname'] as String?,
      primaryDepartment: Department.fromJson(
        json['primaryDepartment']! as Map<String, Object?>,
      ),
      admissionYear: json['admissionYear']! as int,
      enrollmentStatus: json['enrollmentStatus']! as String,
      accountStatus: json['accountStatus']! as String,
    );
  }

  final String studentEntityId;
  final String email;
  final String? nickname;
  final Department primaryDepartment;
  final int admissionYear;
  final String enrollmentStatus;
  final String accountStatus;
}

class StudentRegistration {
  const StudentRegistration({
    required this.primaryDepartmentEntityId,
    required this.admissionYear,
    required this.enrollmentStatus,
    this.nickname,
  });

  final String primaryDepartmentEntityId;
  final int admissionYear;
  final String enrollmentStatus;
  final String? nickname;

  Map<String, Object> toJson() {
    return {
      'primaryDepartmentEntityId': primaryDepartmentEntityId,
      'admissionYear': admissionYear,
      'enrollmentStatus': enrollmentStatus,
      if (nickname case final value? when value.trim().isNotEmpty)
        'nickname': value.trim(),
    };
  }
}

enum StudentApiFailureKind {
  studentNotFound,
  unauthorized,
  validation,
  recoverable,
}

class StudentApiFailure implements Exception {
  const StudentApiFailure(this.kind, this.userMessage);

  final StudentApiFailureKind kind;
  final String userMessage;
}

abstract interface class StudentApi {
  Future<StudentProfile> getProfile(String accessToken);

  Future<List<Department>> getDepartments();

  Future<StudentProfile> registerProfile(
    String accessToken,
    StudentRegistration registration,
  );
}

class HttpStudentApi implements StudentApi {
  HttpStudentApi({required this.baseUri, required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<StudentProfile> getProfile(String accessToken) async {
    final response = await _request(
      () => _client.get(
        baseUri.resolve('/api/v1/students/me'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) throw _failure(response);
    return _decodeProfile(response);
  }

  @override
  Future<List<Department>> getDepartments() async {
    final response = await _request(
      () => _client.get(baseUri.resolve('/api/v1/departments')),
    );
    if (response.statusCode != 200) throw _failure(response);
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
      return body
          .map((item) => Department.fromJson(item! as Map<String, Object?>))
          .toList(growable: false);
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<StudentProfile> registerProfile(
    String accessToken,
    StudentRegistration registration,
  ) async {
    final response = await _request(
      () => _client.post(
        baseUri.resolve('/api/v1/students/me'),
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode(registration.toJson()),
      ),
    );
    if (response.statusCode != 201) throw _failure(response);
    return _decodeProfile(response);
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const StudentApiFailure(
        StudentApiFailureKind.recoverable,
        '서버에 연결하지 못했습니다.\n네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
  }

  StudentProfile _decodeProfile(http.Response response) {
    try {
      return StudentProfile.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  StudentApiFailure _failure(http.Response response) {
    final code = _errorCode(response);
    if (response.statusCode == 401) {
      return const StudentApiFailure(
        StudentApiFailureKind.unauthorized,
        '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      );
    }
    if (response.statusCode == 404 && code == 'STUDENT_NOT_FOUND') {
      return const StudentApiFailure(
        StudentApiFailureKind.studentNotFound,
        '학생 정보를 등록해 주세요.',
      );
    }
    if (response.statusCode >= 500) {
      return const StudentApiFailure(
        StudentApiFailureKind.recoverable,
        '서버 응답이 지연되고 있습니다.\n잠시 후 다시 시도해 주세요.',
      );
    }
    return StudentApiFailure(StudentApiFailureKind.validation, switch (code) {
      'DEPARTMENT_NOT_FOUND' => '학과 정보를 다시 선택해 주세요.',
      'STUDENT_ALREADY_REGISTERED' => '이미 등록된 학생입니다. 다시 불러와 주세요.',
      'INVALID_ENROLLMENT_STATUS' => '재학 또는 휴학 상태를 선택해 주세요.',
      _ => '입력한 정보를 확인해 주세요.',
    });
  }

  String? _errorCode(http.Response response) {
    try {
      return _decodeMap(response)['code'] as String?;
    } on Object catch (_) {
      return null;
    }
  }

  Map<String, Object?> _decodeMap(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
  }

  static const _malformedResponse = StudentApiFailure(
    StudentApiFailureKind.recoverable,
    '서버 응답을 확인하지 못했습니다.\n다시 시도해 주세요.',
  );
}
