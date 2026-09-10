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
    expect(paths, contains('/api/v1/departments'));
  });
}
