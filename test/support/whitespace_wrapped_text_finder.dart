import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:flutter_test/flutter_test.dart';

Finder findWhitespaceWrappedText(String data) {
  return find.byWidgetPredicate(
    (widget) => widget is WhitespaceWrappedText && widget.data == data,
  );
}
