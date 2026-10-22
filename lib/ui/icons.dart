import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The app's own line icons: 24 grid, 1.8 stroke, round caps and joins,
/// drawn in `currentColor`. A few shapes follow Lucide / Feather (ISC / MIT).
/// The same SVG markup is used in the Claude Design mockups.
class AppIcons {
  static const today =
      '<rect x="3.5" y="5" width="17" height="15.5" rx="4"/><path d="M8 3v4M16 3v4M3.5 10h17"/><circle cx="12" cy="15.2" r="2.1" fill="currentColor" stroke="none"/>';
  static const week =
      '<rect x="3.5" y="4" width="17" height="16.5" rx="4"/><path d="M3.5 9.5h17M9.2 9.5v11M14.8 9.5v11M3.5 15h17"/>';

  /// Self-study: an open book with a spark — what goes inside a class slot.
  static const study =
      '<path d="M12 7.6c-2.2-1.6-5.2-1.9-8-1.1v12.2c2.8-.8 5.8-.5 8 1.1 2.2-1.6 5.2-1.9 8-1.1V6.5c-.6-.2-1.2-.3-1.8-.4M12 7.6v12.2"/><path d="M17 1.6l.75 1.9 1.9.75-1.9.75L17 6.9l-.75-1.9-1.9-.75 1.9-.75z" fill="currentColor" stroke="none"/>';
  static const settings =
      '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>';
  static const pin =
      '<path d="M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0c0 5.4-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.4"/>';
  static const person =
      '<circle cx="12" cy="8" r="3.6"/><path d="M5 20c.8-3.6 3.6-5.5 7-5.5s6.2 1.9 7 5.5"/>';
  static const clock =
      '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>';
  static const bell =
      '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 1.5h-15zM10 20.5a2.2 2.2 0 0 0 4 0"/>';
  static const moon =
      '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>';
  static const sun =
      '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M4.6 4.6 6 6M18 18l1.4 1.4M2.5 12h2M19.5 12h2M4.6 19.4 6 18M18 6l1.4-1.4"/>';

  /// The one-minute reflection: a lotus.
  static const lotus =
      '<path d="M12 19.5c-4 0-7.5-2.4-8.5-5.9 3 0 5.6 1 7.1 3M12 19.5c4 0 7.5-2.4 8.5-5.9-3 0-5.6 1-7.1 3M12 19.5c-2.1-2-3.1-4.5-3.1-7.4 1-1.6 2-2.9 3.1-3.9 1.1 1 2.1 2.3 3.1 3.9 0 2.9-1 5.4-3.1 7.4z"/>';
  static const fileImport =
      '<path d="M14 3.5H7.5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2V8z"/><path d="M14 3.5V8h4.5M12 11v6M9.5 14.5 12 17l2.5-2.5"/>';
  static const calendarCheck =
      '<rect x="3.5" y="5" width="17" height="15.5" rx="4"/><path d="M8 3v4M16 3v4M3.5 10h17M9 15l2 2 4-4"/>';
  static const layers =
      '<path d="M12 3.5 20.5 8 12 12.5 3.5 8z"/><path d="M3.5 12 12 16.5 20.5 12M3.5 16 12 20.5 20.5 16"/>';
  static const eye =
      '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>';
  static const island =
      '<rect x="3.5" y="8" width="17" height="8" rx="4"/><circle cx="8" cy="12" r="1.4" fill="currentColor" stroke="none"/><path d="M12 12h4.5"/>';
  static const palette =
      '<path d="M12 3.5a8.5 8.5 0 1 0 0 17c1.2 0 1.8-.8 1.8-1.7 0-1.3-1.2-1.6-1.2-2.8 0-1 .8-1.7 1.8-1.7h2.1a4 4 0 0 0 4-4C20.5 6.6 16.7 3.5 12 3.5z"/><circle cx="7.8" cy="11" r="1.1" fill="currentColor" stroke="none"/><circle cx="10.6" cy="7.6" r="1.1" fill="currentColor" stroke="none"/><circle cx="15" cy="7.8" r="1.1" fill="currentColor" stroke="none"/>';
  static const image =
      '<rect x="3.5" y="4.5" width="17" height="15" rx="3.5"/><circle cx="9" cy="10" r="1.8"/><path d="m20.5 16-5-5-8.5 8.5"/>';
  static const journal =
      '<path d="M6 3.5h10.5a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6zM6 3.5v17M9.5 8h5.5M9.5 11.5h5.5"/>';
  static const info =
      '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8h.01"/>';
  static const shield =
      '<path d="M12 3.5 19 6v5.5c0 4.5-3 8-7 9.5-4-1.5-7-5-7-9.5V6z"/><path d="m9 12 2 2 4-4"/>';

  /// Auto-arrange: a wand with two sparks.
  static const wand =
      '<path d="M5 19 15.5 8.5M13.5 6.5l4 4"/><path d="m18.5 2.5.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7zM7 3.5l.5 1.2 1.2.5-1.2.5L7 7l-.5-1.3-1.2-.5 1.2-.5z" fill="currentColor" stroke="none"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const close = '<path d="M6 6l12 12M18 6 6 18"/>';
  static const check = '<path d="m5 12.5 4.5 4.5L19 7.5"/>';
  static const chevronLeft = '<path d="m15 5-7 7 7 7"/>';
  static const chevronRight = '<path d="m9 5 7 7-7 7"/>';
  static const chevronDown = '<path d="m6 9 6 6 6-6"/>';
  static const back = '<path d="M19 12H5M11 6l-6 6 6 6"/>';
  static const list =
      '<path d="M9 6.5h11M9 12h11M9 17.5h11"/><circle cx="4.8" cy="6.5" r="1.1" fill="currentColor" stroke="none"/><circle cx="4.8" cy="12" r="1.1" fill="currentColor" stroke="none"/><circle cx="4.8" cy="17.5" r="1.1" fill="currentColor" stroke="none"/>';
  static const flame =
      '<path d="M12 21c-3.9 0-6.5-2.6-6.5-6.2 0-3.4 2.6-5.3 3.8-8.3.7 1.9 1.9 3 3.3 3.6-.2-2.3.6-4.6 2.2-6.6.7 3.2 3.7 5.6 3.7 10.1 0 4-2.6 7.4-6.5 7.4z"/>';
  static const target =
      '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.8"/><circle cx="12" cy="12" r="1.3" fill="currentColor" stroke="none"/>';
  static const trash =
      '<path d="M4.5 7h15M9.5 7V4.5h5V7M6.5 7l.8 12.5h9.4L17.5 7"/>';
  static const undo =
      '<path d="M9 14 4.5 9.5 9 5"/><path d="M4.5 9.5H15a5 5 0 0 1 0 10h-3"/>';
  static const coffee =
      '<path d="M5 9h11v5a5 5 0 0 1-5 5h-1a5 5 0 0 1-5-5zM16 10.5h1.5a2.5 2.5 0 0 1 0 5H16M8 3.5c0 1 1 1.3 1 2.3M11.5 3.5c0 1 1 1.3 1 2.3"/>';
  static const calendarPlus =
      '<rect x="3.5" y="5" width="17" height="15.5" rx="4"/><path d="M8 3v4M16 3v4M3.5 10h17M12 12.5v5M9.5 15h5"/>';
  static const repeat =
      '<path d="M4 11V9a3 3 0 0 1 3-3h12l-3-3M20 13v2a3 3 0 0 1-3 3H5l3 3"/>';
  static const book =
      '<path d="M12 7.6c-2.2-1.6-5.2-1.9-8-1.1v12.2c2.8-.8 5.8-.5 8 1.1 2.2-1.6 5.2-1.9 8-1.1V6.5c-2.8-.8-5.8-.5-8 1.1zM12 7.6v12.2"/>';
}

/// Renders one of [AppIcons] in [color] (defaults to the miuix content
/// color).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.svg, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 1.8,
  });

  final String svg;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? MiuixTheme.of(context).colors.onSurface;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
      'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">$svg</svg>',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: tint),
      excludeFromSemantics: true,
    );
  }
}

/// HyperOS settings-style leading tile: a colored squircle with a white icon.
class IconTile extends StatelessWidget {
  const IconTile(this.svg, {super.key, required this.color, this.size = 32});

  final String svg;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: ShapeDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(color, const Color(0xFFFFFFFF), 0.18)!, color],
      ),
      shape: MiuixSquircleBorder(cornerRadius: size * 0.3),
    ),
    child: AppIcon(
      svg,
      size: size * 0.6,
      color: const Color(0xFFFFFFFF),
      strokeWidth: 2,
    ),
  );
}

/// Tile colors for settings groups.
class TileColors {
  static const orange = Color(0xFFF26B1D);
  static const blue = Color(0xFF3482FF);
  static const purple = Color(0xFF8A5CF6);
  static const teal = Color(0xFF14A38B);
  static const pink = Color(0xFFE5487D);
  static const amber = Color(0xFFE59A16);
  static const slate = Color(0xFF6B7684);
}
