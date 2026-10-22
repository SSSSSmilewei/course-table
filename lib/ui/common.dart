import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import '../app_state.dart';
import 'tokens.dart';

/// Messages shown at the bottom of the app.
final appSnackbar = MiuixSnackbarHostState();

void toast(String message) => appSnackbar.showSnackbar(message);

/// Makes the [AppState] reachable from any page and rebuilds dependents when
/// it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// A HyperOS line icon by name (extended set, falling back to OS4).
Widget os4Icon(String name, {double size = 24, Color? tint}) {
  final vector = MiuixIcons.extended.byName(name) ?? MiuixIcons.os4.byName(name);
  return MiuixIcon(vector: vector ?? MiuixIcons.basic.arrowRight, size: size, tint: tint);
}

/// A white miuix card with the standard 12 dp page margin.
class PageCard extends StatelessWidget {
  const PageCard({super.key, required this.child, this.onPressed, this.padding = EdgeInsets.zero});

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: MiuixCard(
          insideMargin: padding,
          onPressed: onPressed,
          child: child,
        ),
      );
}

/// Section label above a card, aligned with the card's content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TypeScale.section.copyWith(color: palette.secondary)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Large page title with a meta line above it, used by pages that need
/// controls beside the title instead of a collapsing top bar.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.meta, this.trailing, this.onTitleTap});

  final String title;
  final String? meta;
  final Widget? trailing;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (meta != null)
          Text(meta!, style: TypeScale.secondary.copyWith(color: palette.secondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TypeScale.page.copyWith(color: palette.ink)),
            if (onTitleTap != null) ...[
              const SizedBox(width: 6),
              CustomPaint(size: const Size(14, 9), painter: _ChevronDown(palette.secondary)),
            ],
          ],
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: onTitleTap == null
                ? titleBlock
                : MiuixPressable(
                    onPressed: onTitleTap,
                    semanticLabel: '选择周次',
                    borderRadius: BorderRadius.circular(12),
                    child: Align(alignment: Alignment.centerLeft, child: titleBlock),
                  ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Round icon button on a card-colored disc.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.label, required this.onPressed});

  final String icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(context);
    return Semantics(
      label: label,
      button: true,
      child: MiuixIconButton(
        onPressed: onPressed,
        backgroundColor: palette.card,
        child: os4Icon(icon, size: 22, tint: palette.ink),
      ),
    );
  }
}

/// Small rounded label, e.g. the 里 badge.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, required this.background, required this.foreground, this.leading});

  final String text;
  final Color background;
  final Color foreground;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(leading == null ? 8 : 4, 2, 8, 2),
        decoration: ShapeDecoration(
          color: background,
          shape: MiuixSquircleBorder(cornerRadius: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TypeScale.chip.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      );
}

/// The "里 · 任务" chip shown inside a 表 course.
class InnerPlanChip extends StatelessWidget {
  const InnerPlanChip({super.key, required this.title, this.done = false});

  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(context);
    return Pill(
      text: done ? '$title · 已完成' : title,
      background: palette.tint,
      foreground: palette.accentText,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: ShapeDecoration(
          color: palette.accentText,
          shape: MiuixSquircleBorder(cornerRadius: 5),
        ),
        child: Text('里', style: TypeScale.chip.copyWith(color: palette.card)),
      ),
    );
  }
}

/// A plain slide-in page route that needs no Material ancestor.
class SlideRoute<T> extends PageRouteBuilder<T> {
  SlideRoute(WidgetBuilder builder)
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          // Material only supplies the default text style and ink layer that
          // miuix text fields expect; it draws nothing.
          pageBuilder: (context, _, _) =>
              Material(type: MaterialType.transparency, child: builder(context)),
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.22, 1, 0.36, 1),
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
              child: child,
            );
          },
        );
}

/// Primary (accent filled) full-width button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.text, required this.onPressed, this.expand = true});

  final String text;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = MiuixTextButton(
      text,
      onPressed: onPressed,
      colors: MiuixButtonDefaults.buttonColorsPrimary(context),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary (grey) button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.text, required this.onPressed, this.expand = true});

  final String text;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = MiuixTextButton(text, onPressed: onPressed);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ChevronDown extends CustomPainter {
  const _ChevronDown(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(1, 1)
        ..lineTo(size.width / 2, size.height - 1)
        ..lineTo(size.width - 1, 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChevronDown old) => old.color != color;
}
