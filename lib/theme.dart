import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF13283C);
  static const inkMuted = Color(0xFF5A6B7B);
  static const inkFaint = Color(0xFF8C9AA7);
  static const teal = Color(0xFF0A8F82);
  static const tealDeep = Color(0xFF076A61);
  static const tealWash = Color(0xFFE7F4F2);
  // static const skin = Color(0xFFFBEDE3);
  // static const skinDeep = Color(0xFFE9B99A);
  static const line = Color(0xFFDFE6E8);
  static const paper = Color(0xFFFFFFFF);
  static const danger = Color(0xFFB42318);
  // static const dangerWash = Color(0xFFFDEEEC);
  static const warning = Color(0xFF9A5B00);
  static const warningWash = Color(0xFFFFF5E6);
}

const _font = 'Manrope';

abstract final class AppText {
  static const caption = TextStyle(fontFamily: _font, fontWeight: FontWeight.w500, fontSize: 13, height: 18 / 13);
  static const body = TextStyle(fontFamily: _font, fontWeight: FontWeight.w400, fontSize: 15, height: 22 / 15);
  static const lead = TextStyle(fontFamily: _font, fontWeight: FontWeight.w600, fontSize: 17, height: 24 / 17);
  // static const title = TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, fontSize: 22, height: 28 / 22);
  static const display = TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, fontSize: 28, height: 34 / 28, letterSpacing: -0.4);
  static const label = TextStyle(fontFamily: _font, fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink);
  static const input = TextStyle(fontFamily: _font, fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.ink);
  static const button = TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, fontSize: 16);
}

final appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: _font,
  scaffoldBackgroundColor: AppColors.paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    primary: AppColors.teal,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
    error: AppColors.danger,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.teal),
  dialogTheme: const DialogThemeData(backgroundColor: AppColors.paper),
);
