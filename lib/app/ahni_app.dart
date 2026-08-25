import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';

class AhniApp extends StatelessWidget {
  const AhniApp({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1558A6);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: const Color(0xFFF7F8FA),
    ).copyWith(primary: accent);

    return MaterialApp(
      title: 'AHNI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Color(0xFF18202A),
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 36 / 28,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF5B6470),
            fontSize: 16,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            color: Color(0xFF5B6470),
            fontSize: 14,
            height: 20 / 14,
          ),
        ),
      ),
      home: HomePage(environment: environment),
    );
  }
}
