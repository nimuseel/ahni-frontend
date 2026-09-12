import 'package:flutter/widgets.dart';

class WhitespaceWrappedText extends StatelessWidget {
  const WhitespaceWrappedText(
    this.data, {
    this.style,
    this.textAlign,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      data.replaceAllMapped(
        RegExp(r'\S+'),
        (match) => match.group(0)!.characters.join('\u2060'),
      ),
      semanticsLabel: data,
      style: style,
      textAlign: textAlign,
    );
  }
}
