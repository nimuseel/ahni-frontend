import 'dart:convert';

import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';
import 'package:http/http.dart' as http;

enum GraduationFailureKind { unauthorized, policyMissing, recoverable }

class GraduationApiFailure implements Exception {
  const GraduationApiFailure(this.kind, this.message);
  final GraduationFailureKind kind;
  final String message;
}

abstract interface class GraduationApi {
  Future<List<GraduationOverview>> getOverview(String accessToken);
}

class HttpGraduationApi implements GraduationApi {
  HttpGraduationApi({required this.baseUri, required this.client});
  final Uri baseUri;
  final http.Client client;
  @override
  Future<List<GraduationOverview>> getOverview(String accessToken) async {
    final responses = await Future.wait([
      _get('/api/v1/graduation-requirements', accessToken),
      _get('/api/v1/graduation-progress', accessToken),
    ]);
    try {
      final requirements =
          jsonDecode(utf8.decode(responses[0].bodyBytes)) as List<Object?>;
      final progress =
          jsonDecode(utf8.decode(responses[1].bodyBytes)) as List<Object?>;
      if (requirements.length != progress.length) {
        throw const FormatException('Incomplete policy set');
      }
      final byId = <String, Map<String, Object?>>{};
      for (final item in progress) {
        final row = item! as Map<String, Object?>;
        final id = row['requirementEntityId']! as String;
        if (byId.containsKey(id)) {
          throw const FormatException('Duplicate policy');
        }
        byId[id] = row;
      }
      return List.unmodifiable(
        requirements.map((item) {
          final row = item! as Map<String, Object?>;
          final matched = byId.remove(row['entityId']);
          if (matched == null) throw const FormatException('Missing policy');
          return GraduationOverview.fromJson(row, matched);
        }),
      );
    } on FormatException catch (_) {
      throw _malformed;
    } on TypeError catch (_) {
      throw _malformed;
    }
  }

  Future<http.Response> _get(String path, String token) async {
    final http.Response response;
    try {
      response = await client
          .get(
            baseUri.resolve(path),
            headers: {'authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const GraduationApiFailure(
        GraduationFailureKind.recoverable,
        '서버에 연결하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
    if (response.statusCode == 200) return response;
    if (response.statusCode == 401) {
      throw const GraduationApiFailure(
        GraduationFailureKind.unauthorized,
        '다시 로그인해 주세요.',
      );
    }
    if (response.statusCode == 404) {
      try {
        final body = jsonDecode(response.body) as Map<String, Object?>;
        if (body['code'] == 'GRADUATION_REQUIREMENT_NOT_FOUND') {
          throw const GraduationApiFailure(
            GraduationFailureKind.policyMissing,
            '아직 등록된 졸업 기준이 없어요. 학과와 입학연도를 확인해 주세요.',
          );
        }
      } on FormatException catch (_) {
        throw _malformed;
      } on TypeError catch (_) {
        throw _malformed;
      }
    }
    throw const GraduationApiFailure(
      GraduationFailureKind.recoverable,
      '졸업 정보를 불러오지 못했어요. 다시 시도해 주세요.',
    );
  }

  static const _malformed = GraduationApiFailure(
    GraduationFailureKind.recoverable,
    '졸업 정보를 확인하지 못했어요. 다시 시도해 주세요.',
  );
}
