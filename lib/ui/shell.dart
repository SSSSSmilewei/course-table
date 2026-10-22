import 'dart:io';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import '../notification_service.dart';
import 'common.dart';
import 'icons.dart';
import 'glass.dart';
import 'plan_page.dart';
import 'reflection_page.dart';
import 'settings_page.dart';
import 'today_page.dart';
import 'tokens.dart';
import 'week_page.dart';

/// Four tabs under a floating glass navigation bar. The glass samples the
/// page content through [MiuixLayerBackdropCapture].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _backdrop = MiuixLayerBackdrop();
  int _tab = 0;
  final _weekPage = GlobalKey<WeekPageState>();

  static const _tabs = [
    ('今天', AppIcons.today),
    ('课表', AppIcons.week),
    ('自学', AppIcons.study),
    ('设置', AppIcons.settings),
  ];

  @override
  void initState() {
    super.initState();
    final notifications = NotificationService();
    notifications.onTap = _openPayload;
    notifications.launchPayload().then((payload) {
      if (payload != null && mounted) _openPayload(payload);
    });
  }

  @override
  void dispose() {
    _backdrop.dispose();
    super.dispose();
  }

  void _openPayload(String payload) {
    final evening = payload == NotificationService.eveningPayload;
    if (payload != NotificationService.morningPayload && !evening) return;
    Navigator.of(
      context,
    ).push(SlideRoute((_) => ReflectionPage(evening: evening), ambient: false));
  }

  /// Jumps to the week tab showing [week].
  void showWeek(int week) {
    setState(() => _tab = 1);
    _weekPage.currentState?.jumpToWeek(week);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = Palette(context);
    final background = state.appearance.backgroundPath;
    final pages = [
      TodayPage(onOpenWeek: () => setState(() => _tab = 1)),
      WeekPage(key: _weekPage),
      const PlanPage(),
      const SettingsPage(),
    ];
    return Material(
      type: MaterialType.transparency,
      child: MiuixScaffold(
        containerColor: palette.surface,
        snackbarHost: MiuixSnackbarHost(state: appSnackbar, blurSigma: 20),
        bottomBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: MiuixGlassNavigationBar(
              backdrop: _backdrop,
              selectedIndex: _tab,
              onSelect: (index) {
                if (index == _tab) return;
                HapticFeedback.selectionClick();
                setState(() => _tab = index);
              },
              items: [
                for (final (label, icon) in _tabs)
                  MiuixGlassNavigationItem(
                    icon: AppIcon(icon, size: 24),
                    label: label,
                  ),
              ],
            ),
          ),
        ),
        content: (padding) {
          final media = MediaQuery.of(context);
          return MiuixLayerBackdropCapture(
            backdrop: _backdrop,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const AmbientBackground(),
                if (background != null && File(background).existsSync()) ...[
                  Image.file(File(background), fit: BoxFit.cover),
                  // A wash keeps text readable on any wallpaper; the
                  // "visibility" setting decides how much picture shows.
                  ColoredBox(
                    color:
                        (palette.dark
                                ? const Color(0xFF000000)
                                : const Color(0xFFFAFAFA))
                            .withValues(
                              alpha: 1 - state.appearance.backgroundOpacity,
                            ),
                  ),
                ],
                MediaQuery(
                  data: media.copyWith(
                    padding: media.padding.copyWith(bottom: padding.bottom),
                  ),
                  child: IndexedStack(index: _tab, children: pages),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
