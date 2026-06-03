import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.dark); // Por defecto en modo oscuro

  void setTheme(AppThemeMode themeMode) {
    state = themeMode;
  }

  void toggleTheme() {
    switch (state) {
      case AppThemeMode.light:
        state = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        state = AppThemeMode.amoled;
        break;
      case AppThemeMode.amoled:
        state = AppThemeMode.light;
        break;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
