import 'package:flutter/material.dart';

const Color kGoogleBlue = Color.fromRGBO(26, 115, 232, 1);
const Color kGoogleRed = Color(0xFFDF0D18);
const Color kScaffoldBg = Color(0xFFF1F5F9);
const Color kFastOfficePink = Color(0xFFFFD1DC);

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

bool isGlassDark(BuildContext context) {
  final mode = appThemeMode.value;
  if (mode == ThemeMode.system) {
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
  return mode == ThemeMode.dark;
}
