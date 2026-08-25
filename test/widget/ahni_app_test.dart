import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the development-ready AHNI app shell', (tester) async {
    await tester.pumpWidget(
      const AhniApp(environment: AppEnvironment.development),
    );

    expect(find.text('AHNI'), findsOneWidget);
    expect(find.text('개발 환경이 준비되었습니다.'), findsOneWidget);
    expect(find.text('환경: development'), findsOneWidget);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final appBarTitle = appBar.title! as Text;
    final theme = Theme.of(tester.element(find.byType(Scaffold)));

    expect(theme.colorScheme.primary, const Color(0xFF1558A6));
    expect(appBar.titleSpacing, 24);
    expect(appBarTitle.style!.fontSize, 20);
    expect(appBarTitle.style!.height, 1.4);
  });

  testWidgets('keeps the compact title on phrase boundaries', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const AhniApp(environment: AppEnvironment.development),
    );

    expect(find.text('학사 생활을 위한\n준비를 시작합니다.'), findsOneWidget);
  });
}
