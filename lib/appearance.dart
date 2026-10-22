enum AppThemeMode { system, light, dark }

class AppearanceSettings {
  const AppearanceSettings({
    this.themeMode = AppThemeMode.system,
    this.backgroundPath,
    this.backgroundOpacity = 0.25,
  });

  final AppThemeMode themeMode;
  final String? backgroundPath;
  final double backgroundOpacity;

  AppearanceSettings copyWith({
    AppThemeMode? themeMode,
    String? backgroundPath,
    bool removeBackground = false,
    double? backgroundOpacity,
  }) => AppearanceSettings(
    themeMode: themeMode ?? this.themeMode,
    backgroundPath: removeBackground
        ? null
        : backgroundPath ?? this.backgroundPath,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
  );
}
