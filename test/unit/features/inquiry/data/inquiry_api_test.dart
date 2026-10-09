import 'dart:convert';

import 'package:ahni_mobile/features/inquiry/data/inquiry_api.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const draft = InquiryDraft(title: ' 수정 문의 ', content: ' 수정 내용입니다. ');

  test(
    'PUT /inquiries/{id} sends trimmed values and parses the result',
    () async {
      final api = HttpInquiryApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/inquiries/inquiry-id-1');
          expect(request.headers['authorization'], 'Bearer jwt');
          expect(jsonDecode(request.body), {
            'title': '수정 문의',
            'content': '수정 내용입니다.',
          });
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'entityId': 'inquiry-id-1',
                'title': '수정 문의',
                'content': '수정 내용입니다.',
                'status': 'IN_REVIEW',
                'answer': null,
                'answeredAt': null,
                'createdAt': '2026-10-09T00:00:00Z',
                'updatedAt': '2026-10-10T00:00:00Z',
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final inquiry = await api.updateInquiry('jwt', 'inquiry-id-1', draft);

      expect(inquiry.title, '수정 문의');
      expect(inquiry.content, '수정 내용입니다.');
      expect(inquiry.status, 'IN_REVIEW');
    },
  );

  test('DELETE /inquiries/{id} accepts an empty 204 response', () async {
    final api = HttpInquiryApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/inquiries/inquiry-id-1');
        expect(request.headers['authorization'], 'Bearer jwt');
        return http.Response('', 204);
      }),
    );

    await api.deleteInquiry('jwt', 'inquiry-id-1');
  });

  test('answered inquiry update conflict uses a specific message', () async {
    final api = HttpInquiryApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'code': 'INQUIRY_UPDATE_CONFLICT',
              'message': '답변이 등록된 문의는 수정할 수 없습니다.',
            }),
          ),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    expect(
      () => api.updateInquiry('jwt', 'inquiry-id-1', draft),
      throwsA(
        isA<InquiryApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              InquiryApiFailureKind.conflict,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '답변이 등록된 문의는 수정할 수 없어요.',
            ),
      ),
    );
  });
}
