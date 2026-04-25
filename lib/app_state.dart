import 'package:flutter/material.dart';

/// Global theme mode. Toggle from Profile → Theme setting.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
