import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:ahni_mobile/features/onboarding/presentation/onboarding_page.dart';
import 'package:flutter/material.dart';

class AhniApp extends StatelessWidget {
  const AhniApp({
    required this.environment,
    required this.controller,
    super.key,
  });

  final AppEnvironment environment;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1558A6);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: Colors.white,
        ).copyWith(
          primary: accent,
          onSurface: const Color(0xFF18202A),
          outline: const Color(0xFFDDE2E8),
        );

    return MaterialApp(
      title: 'AHNI',
      restorationScopeId: 'ahni-${environment.name}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          foregroundColor: Color(0xFF18202A),
          titleTextStyle: TextStyle(
            color: Color(0xFF18202A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: -0.3,
          ),
        ),
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFDDE2E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFDDE2E8)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
      ),
      home: OnboardingPage(controller: controller),
    );
  }
}
