// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:http/http.dart' as http;

enum GradeApiFailureKind { unauthorized, studentNotFound, recoverable }

class GradeApiFailure implements Exception {
  const GradeApiFailure(this.kind, this.userMessage);

  final GradeApiFailureKind kind;
  final String userMessage;
}

abstract interface class GradeApi {
  Future<List<GradeRecord>> getGrades(String accessToken);
}

class HttpGradeApi implements GradeApi {
  HttpGradeApi({required this.baseUri, required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<List<GradeRecord>> getGrades(String accessToken) async {
    final response = await _request(
      () => _client.get(
        baseUri.resolve('/api/v1/grades'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) throw _failure(response);
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
      return body
          .map((item) => GradeRecord.fromJson(item! as Map<String, Object?>))
          .toList(growable: false);
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const GradeApiFailure(
        GradeApiFailureKind.recoverable,
        '서버에 연결하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
  }

  GradeApiFailure _failure(http.Response response) {
    if (response.statusCode == 401) {
      return const GradeApiFailure(
        GradeApiFailureKind.unauthorized,
        '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      );
    }
    if (response.statusCode == 404) {
      return const GradeApiFailure(
        GradeApiFailureKind.studentNotFound,
        '학생 정보를 먼저 등록해 주세요.',
      );
    }
    return const GradeApiFailure(
      GradeApiFailureKind.recoverable,
      '성적 목록을 불러오지 못했습니다. 다시 시도해 주세요.',
    );
  }

  static const _malformedResponse = GradeApiFailure(
    GradeApiFailureKind.recoverable,
    '성적 정보를 확인하지 못했습니다. 다시 시도해 주세요.',
  );
}
