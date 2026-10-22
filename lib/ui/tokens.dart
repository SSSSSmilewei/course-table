
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// HIANA brand colors layered on top of the miuix color scheme.
class Brand {
  static const accent = Color(0xFFF26B1D);
  static const hero = Color(0xFFC2410F);

  static Color accentText(bool dark) =>
      dark ? const Color(0xFFFF9A5C) : const Color(0xFFB8460B);

  static Color tint(bool dark) => dark
      ? const Color(0x2EFF7A2E) // 18%
      : const Color(0x1FF26B1D); // 12%

  /// Fill and text for a 里课 card in the grid.
  static Color planFill(bool dark) =>
      dark ? const Color(0xFF4A2410) : const Color(0xFFFFE6D5);
  static Color planInk(bool dark) =>
      dark ? const Color(0xFFFFB98A) : const Color(0xFF8F3508);

  static MiuixColors light() => lightColorScheme().copy(
        primary: const Color(0xFFE2601F),
        onSurface: const Color(0xFF1A1A1A),
      );

  static MiuixColors dark() => darkColorScheme().copy(
        primary: const Color(0xFFE2601F),
      );
}

/// Pastel course colors, each a (fill, ink) pair per brightness.
/// Picked by a stable hash of the course name so a course keeps its color.
class CoursePalette {
  static const _light = [
    (Color(0xFFE3ECFF), Color(0xFF1E4FB0)),
    (Color(0xFFDDF4E8), Color(0xFF14724A)),
    (Color(0xFFFCEFD6), Color(0xFF8A5A06)),
    (Color(0xFFFBE3EE), Color(0xFF9C2F5E)),
    (Color(0xFFECE6FF), Color(0xFF5638B0)),
    (Color(0xFFDDF2F7), Color(0xFF0E6378)),
    (Color(0xFFF3E9DF), Color(0xFF7A4A1E)),
    (Color(0xFFE6F0D9), Color(0xFF3F6A12)),
  ];
  static const _dark = [
    (Color(0xFF1D2B4A), Color(0xFFA9C4FF)),
    (Color(0xFF173A2B), Color(0xFF8FE0B8)),
    (Color(0xFF3E2E10), Color(0xFFF5C873)),
    (Color(0xFF3E1D2C), Color(0xFFF7A6C8)),
    (Color(0xFF2B2347), Color(0xFFC9B5FF)),
    (Color(0xFF183640), Color(0xFF8FD9EC)),
    (Color(0xFF3A2A1C), Color(0xFFE8C29C)),
    (Color(0xFF26331A), Color(0xFFBFE08F)),
  ];

  static (Color fill, Color ink) of(String name, bool dark) {
    // FNV-1a: String.hashCode is not guaranteed stable across runs.
    var hash = 0x811c9dc5;
    for (final unit in name.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    final palette = dark ? _dark : _light;
    return palette[hash % palette.length];
  }
}

/// The type scale from the design spec: one family (system MiSans), three
/// weights, nine sizes, 11 at the smallest. Digits are always tabular.
class TypeScale {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle _style(double size, double lineHeight, FontWeight weight) =>
      TextStyle(
        fontSize: size,
        height: lineHeight / size,
        leadingDistribution: TextLeadingDistribution.even,
        fontWeight: weight,
        fontFeatures: _tabular,
        letterSpacing: 0,
      );

  static final timer = _style(40, 48, FontWeight.w500);
  static final page = _style(32, 40, FontWeight.w700);
  static final prompt = _style(24, 34, FontWeight.w700);
  static final stat = _style(24, 30, FontWeight.w700);
  static final hero = _style(20, 28, FontWeight.w700);
  static final card = _style(18, 26, FontWeight.w700);
  static final listTitle = _style(16, 22, FontWeight.w500);
  static final body = _style(16, 24, FontWeight.w400);
  static final time = _style(14, 20, FontWeight.w500);
  static final value = _style(14, 20, FontWeight.w400);
  static final section = _style(14, 20, FontWeight.w500);
  static final secondary = _style(13, 18, FontWeight.w400);
  static final chip = _style(13, 18, FontWeight.w500);
  static final caption = _style(11, 14, FontWeight.w500);
}

/// Shorthand for the colors pages use most.
class Palette {
  Palette(BuildContext context)
      : colors = MiuixTheme.of(context).colors,
        dark = MiuixTheme.of(context).brightness == Brightness.dark;

  final MiuixColors colors;
  final bool dark;

  Color get ink => dark ? const Color(0xFFEDEDED) : const Color(0xFF1A1A1A);
  Color get secondary => dark ? const Color(0xFF9A9A9F) : const Color(0xFF6B6B6F);
  Color get surface => colors.surface;
  Color get card => colors.surfaceContainer;
  Color get line => colors.dividerLine;
  Color get accentText => Brand.accentText(dark);
  Color get tint => Brand.tint(dark);
  Color get ghostFill => dark ? const Color(0xFF2A2A2C) : const Color(0xFFEFEFF1);
  Color get ghostInk => dark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
}

const weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
const weekdayShort = ['一', '二', '三', '四', '五', '六', '日'];

String dateLabel(DateTime date) =>
    '${date.month} 月 ${date.day} 日 ${weekdayNames[date.weekday - 1]}';
