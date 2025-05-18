import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => FlexThemeData.light(
    scheme: FlexScheme.material,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(blendOnLevel: 10, useMaterial3Typography: true, useM2StyleDividerInM3: true),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    swapLegacyOnMaterial3: true,
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData get darkTheme => FlexThemeData.dark(
    scheme: FlexScheme.material,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(blendOnLevel: 20, useMaterial3Typography: true, useM2StyleDividerInM3: true),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    swapLegacyOnMaterial3: true,
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );
}
