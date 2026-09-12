import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps words intact while preserving the readable label', (
    tester,
  ) async {
    const source = '학사 준비, 함께 이어가요';

    await tester.pumpWidget(
      const MaterialApp(home: WhitespaceWrappedText(source)),
    );

    final renderedText = tester.widget<Text>(
      find.descendant(
        of: find.byType(WhitespaceWrappedText),
        matching: find.byType(Text),
      ),
    );
    expect(
      renderedText.data,
      '학\u2060사 준\u2060비\u2060, 함\u2060께 이\u2060어\u2060가\u2060요',
    );
    expect(renderedText.semanticsLabel, source);
  });
}
