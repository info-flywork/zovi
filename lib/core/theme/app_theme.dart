import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zovi/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.zoviOrange,
        primary: AppColors.zoviOrange,
        onPrimary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.deepRoast,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.deepRoast,
        displayColor: AppColors.deepRoast,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.deepRoast,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepRoast,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static TextStyle get brandWordmark => GoogleFonts.pacifico(
        fontSize: 64,
        height: 1,
        letterSpacing: -1.28,
        color: AppColors.black,
      );

  static TextStyle get brandWordmarkSmall => GoogleFonts.pacifico(
        fontSize: 32,
        height: 1.1,
        color: AppColors.deepRoast,
      );
}
