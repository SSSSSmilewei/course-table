import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// Glass over a static ambient background (after Listenly 3.0's liquid
/// glass). Because the background is a smooth gradient, a translucent fill
/// reads as frosted glass without a BackdropFilter; real blur is reserved
/// for surfaces that float over scrolling content.
enum GlassKind {
  /// Content cards: denser fill, soft drop shadow.
  regular,

  /// Small controls (round buttons, chips, segmented tracks): thinner fill.
  clear,
}

class _GlassSpec {
  const _GlassSpec(this.fill, this.edgeTop, this.edgeBottom, this.shadow);
  final Color fill;
  final Color edgeTop;
  final Color edgeBottom;
  final BoxShadow shadow;
}

_GlassSpec _spec(GlassKind kind, bool dark) => switch ((kind, dark)) {
  (GlassKind.regular, false) => const _GlassSpec(
    Color(0x94FFFFFF), // 58 %
    Color(0xD9FFFFFF),
    Color(0x52FFFFFF),
    BoxShadow(color: Color(0x1A5A280A), blurRadius: 30, offset: Offset(0, 10)),
  ),
  (GlassKind.clear, false) => const _GlassSpec(
    Color(0x57FFFFFF), // 34 %
    Color(0xF2FFFFFF),
    Color(0x8CFFFFFF),
    BoxShadow(color: Color(0x241E323C), blurRadius: 24, offset: Offset(0, 8)),
  ),
  (GlassKind.regular, true) => const _GlassSpec(
    Color(0x8C28221E), // 55 %
    Color(0x1AFFFFFF),
    Color(0x0FFFFFFF),
    BoxShadow(color: Color(0x59000000), blurRadius: 30, offset: Offset(0, 10)),
  ),
  (GlassKind.clear, true) => const _GlassSpec(
    Color(0x12FFFFFF), // 7 %
    Color(0x73FFFFFF),
    Color(0x1FFFFFFF),
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
  ),
};

bool _isDark(BuildContext context) =>
    MiuixTheme.of(context).brightness == Brightness.dark;

/// A squircle glass panel: translucent fill, a light rim that is brightest
/// along the top edge, and a soft shadow. Set [blur] when the panel floats
/// over content that moves underneath it.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.kind = GlassKind.regular,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.blur = false,
    this.shadow = true,
  });

  final Widget child;
  final GlassKind kind;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Replaces the fill, e.g. for a selected pill.
  final Color? tint;
  final bool blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(kind, _isDark(context));
    final shape = MiuixSquircleBorder(cornerRadius: radius);
    Widget body = Container(
      padding: padding,
      decoration: ShapeDecoration(color: tint ?? spec.fill, shape: shape),
      child: child,
    );
    if (blur) {
      body = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 11, sigmaY: 11),
          child: body,
        ),
      );
    }
    return CustomPaint(
      foregroundPainter: _GlassRim(
        shape: shape,
        top: spec.edgeTop,
        bottom: spec.edgeBottom,
      ),
      child: body,
    );
  }
}

class _GlassRim extends CustomPainter {
  const _GlassRim({
    required this.shape,
    required this.top,
    required this.bottom,
  });

  final ShapeBorder shape;
  final Color top;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect.deflate(0.5));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        [top, bottom.withValues(alpha: bottom.a * 0.6), bottom],
        const [0, 0.45, 1],
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlassRim old) =>
      old.top != top || old.bottom != bottom || old.shape != shape;
}

/// The page backdrop: a soft warm gradient with one glow, so glass has
/// something to pick up. Light: sand, peach and sage; dark: ember to slate.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.6, -1),
              end: const Alignment(0.6, 1),
              colors: dark
                  ? const [
                      Color(0xFF1B120D),
                      Color(0xFF231712),
                      Color(0xFF171A1A),
                      Color(0xFF0F1312),
                    ]
                  : const [
                      Color(0xFFF4E6D8),
                      Color(0xFFEBD9CB),
                      Color(0xFFE7E2D6),
                      Color(0xFFD8DFD5),
                    ],
              stops: const [0, 0.36, 0.66, 1],
            ),
          ),
        ),
        Positioned(
          left: -220,
          top: 140,
          width: 640,
          height: 760,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: dark
                    ? const [Color(0x47C2410F), Color(0x00C2410F)]
                    : const [Color(0xE6FFF4E8), Color(0x00FFF4E8)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A glass track with a white pill that slides to the selected segment.
class GlassSegmented extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 40,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final ink = dark ? const Color(0xFFEDEDED) : const Color(0xFF1A1A1A);
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 6) / labels.length;
          return Stack(
            children: [
              // Track and sliding pill (visual only).
              Positioned.fill(
                child: GlassSurface(
                  kind: GlassKind.clear,
                  radius: height / 2,
                  padding: const EdgeInsets.all(3),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: still
                            ? Duration.zero
                            : const Duration(milliseconds: 360),
                        // Slight overshoot, like a spring settling.
                        curve: const Cubic(0.3, 1.4, 0.5, 1),
                        left: selected * width,
                        top: 0,
                        bottom: 0,
                        width: width,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: dark
                                ? const Color(0x29FFFFFF)
                                : const Color(0xD9FFFFFF),
                            shape: MiuixSquircleBorder(
                              cornerRadius: (height - 6) / 2,
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x1F1E323C),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Full-height hit areas, so each segment is a 48 dp target.
              Positioned.fill(
                left: 3,
                right: 3,
                child: Row(
                  children: [
                    for (var index = 0; index < labels.length; index++)
                      Expanded(
                        child: Semantics(
                          selected: index == selected,
                          button: true,
                          label: labels[index],
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (index == selected) return;
                              HapticFeedback.selectionClick();
                              onChanged(index);
                            },
                            child: Center(
                              // Weight is not tweened: the two weights
                              // cross-fade, which avoids relayout per frame.
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  for (final weight in const [
                                    FontWeight.w400,
                                    FontWeight.w600,
                                  ])
                                    AnimatedOpacity(
                                      duration: still
                                          ? Duration.zero
                                          : const Duration(milliseconds: 220),
                                      opacity:
                                          (index == selected) ==
                                              (weight == FontWeight.w600)
                                          ? 1
                                          : 0,
                                      child: Text(
                                        labels[index],
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 18 / 13,
                                          fontWeight: weight,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The accent "gel" button: solid fill with a top highlight, an inner
/// shadow at the bottom and a colored glow beneath.
class GelButton extends StatelessWidget {
  const GelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFFE2601F),
    this.foreground = const Color(0xFFFFFFFF),
    this.height = 48,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final shape = MiuixSquircleBorder(cornerRadius: height / 2.6);
    final button = Tappable(
      onPressed: onPressed,
      feedbackType: MiuixPressFeedbackType.sink,
      shape: shape,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            shape: shape,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color, const Color(0xFFFFFFFF), 0.14)!,
                color,
                Color.lerp(color, const Color(0xFF000000), 0.12)!,
              ],
              stops: const [0, 0.55, 1],
            ),
            shadows: enabled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// [MiuixPressable] with its focus node and label merged into one semantics
/// node, so screen readers announce every tappable surface by name.
class Tappable extends StatelessWidget {
  const Tappable({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.feedbackType = MiuixPressFeedbackType.none,
    this.shape,
    this.borderRadius,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final MiuixPressFeedbackType feedbackType;
  final ShapeBorder? shape;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: MiuixPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      feedbackType: feedbackType,
      shape: shape,
      borderRadius: borderRadius,
      child: child,
    ),
  );
}
