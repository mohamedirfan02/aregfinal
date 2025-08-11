import 'package:flutter/material.dart';

import '../common/app_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.white,
  bottomAppBarTheme: BottomAppBarTheme(
    color: AppColors.white,
  ),
  primaryColor: AppColors.primaryGreen,
  unselectedWidgetColor: AppColors.grey,
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryGreen,
    secondary: AppColors.secondaryGreen,
    surface: AppColors.white,
    onPrimary: AppColors.white,
    onSurface: AppColors.textDark,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: AppColors.textDark),
    bodyMedium:  TextStyle(color: AppColors.textDark),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.black,
  bottomAppBarTheme: BottomAppBarTheme(
    color: AppColors.black,
  ),
  primaryColor: AppColors.accentGreen,
  unselectedWidgetColor: Colors.grey,
  colorScheme: ColorScheme.dark(
    primary: AppColors.accentGreen,
    secondary: AppColors.secondaryGreen,
    surface: Colors.black,
    onPrimary: AppColors.white,
    onSurface: AppColors.white,
  ),
  textTheme:  TextTheme(
    bodyLarge: TextStyle(color: AppColors.textLight),
    bodyMedium: TextStyle(color: AppColors.textLight),
  ),
);
