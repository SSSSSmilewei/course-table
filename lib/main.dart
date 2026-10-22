import 'package:flutter/material.dart'
    show MaterialApp, ThemeData, ColorScheme, NoSplash, Typography;
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import 'app_state.dart';
import 'appearance.dart';
import 'ui/common.dart';
import 'ui/shell.dart';
import 'ui/tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  runApp(CourseTableApp(state: state));
  state.load();
}

final navigatorKey = GlobalKey<NavigatorState>();

class CourseTableApp extends StatelessWidget {
  const CourseTableApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MiuixThemeController(
          colorSchemeMode: switch (state.appearance.themeMode) {
            AppThemeMode.system => MiuixColorSchemeMode.system,
            AppThemeMode.light => MiuixColorSchemeMode.light,
            AppThemeMode.dark => MiuixColorSchemeMode.dark,
          },
          lightColors: Brand.light(),
          darkColors: Brand.dark(),
          child: Builder(
            builder: (context) {
              final theme = MiuixTheme.of(context);
              // MaterialApp only hosts localizations and text editing for the
              // miuix widgets; every visible control is a Miuix* widget.
              return MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                title: '课表',
                theme: ThemeData(
                  brightness: theme.brightness,
                  // The 2014 type set carries no line height or letter spacing,
                  // so nothing leaks into miuix text through DefaultTextStyle.
                  typography: Typography.material2014(),
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Brand.accent,
                    brightness: theme.brightness,
                  ),
                  splashFactory: NoSplash.splashFactory,
                ),
                home: const AppShell(),
              );
            },
          ),
        ),
      ),
    );
  }
}
