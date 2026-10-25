import 'custom_event.dart';

/// One card of the 里课表: something the user wants to study inside a period
/// slot, optionally placed on a date and period range.
class PlanItem {
  const PlanItem({
    required this.id,
    required this.title,
    required this.group,
    this.note = '',
    this.date,
    this.startPeriod,
    this.endPeriod,
    this.done = false,
    this.deferCount = 0,
    this.hianaCourse,
    this.hianaUnit,
  });

  final String id;
  final String title;

  /// The self-study course this card belongs to, e.g. "MIT 16.01".
  final String group;
  final String note;
  final DateTime? date;
  final int? startPeriod;
  final int? endPeriod;
  final bool done;

  /// How many times the card went back to the backlog unfinished.
  final int deferCount;

  /// 从协会平台导入的卡片：协会课程 slug 和单元 id。勾掉时会同步到协会。
  final String? hianaCourse;
  final String? hianaUnit;

  bool get linked => hianaCourse != null && hianaUnit != null;

  bool get scheduled =>
      date != null && startPeriod != null && endPeriod != null;

  bool occupies(DateTime day, int period) =>
      scheduled &&
      sameDate(date!, day) &&
      period >= startPeriod! &&
      period <= endPeriod!;

  PlanItem placed(DateTime day, int start, int end) => PlanItem(
    id: id,
    title: title,
    group: group,
    note: note,
    date: dateOnly(day),
    startPeriod: start,
    endPeriod: end,
    done: done,
    deferCount: deferCount,
    hianaCourse: hianaCourse,
    hianaUnit: hianaUnit,
  );

  /// Back to the backlog; counts as a deferral when it was placed but not done.
  PlanItem unplaced() => PlanItem(
    id: id,
    title: title,
    group: group,
    note: note,
    done: false,
    deferCount: scheduled && !done ? deferCount + 1 : deferCount,
    hianaCourse: hianaCourse,
    hianaUnit: hianaUnit,
  );

  PlanItem copyWith({String? title, String? group, String? note, bool? done}) =>
      PlanItem(
        id: id,
        title: title ?? this.title,
        group: group ?? this.group,
        note: note ?? this.note,
        date: date,
        startPeriod: startPeriod,
        endPeriod: endPeriod,
        done: done ?? this.done,
        deferCount: deferCount,
        hianaCourse: hianaCourse,
        hianaUnit: hianaUnit,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'group': group,
    'note': note,
    'date': date?.toIso8601String().split('T').first,
    'startPeriod': startPeriod,
    'endPeriod': endPeriod,
    'done': done,
    'deferCount': deferCount,
    if (hianaCourse != null) 'hianaCourse': hianaCourse,
    if (hianaUnit != null) 'hianaUnit': hianaUnit,
  };

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
    id: json['id'] as String,
    title: json['title'] as String,
    group: json['group'] as String? ?? '',
    note: json['note'] as String? ?? '',
    date: json['date'] == null
        ? null
        : DateTime.tryParse(json['date'] as String),
    startPeriod: json['startPeriod'] as int?,
    endPeriod: json['endPeriod'] as int?,
    done: json['done'] as bool? ?? false,
    deferCount: json['deferCount'] as int? ?? 0,
    hianaCourse: json['hianaCourse'] as String?,
    hianaUnit: json['hianaUnit'] as String?,
  );
}

/// The plan card placed at [period] on [day], if any.
PlanItem? planAt(List<PlanItem> items, DateTime day, int period) {
  for (final item in items) {
    if (item.occupies(day, period)) return item;
  }
  return null;
}

List<PlanItem> plansForDate(List<PlanItem> items, DateTime day) =>
    items.where((item) => item.scheduled && sameDate(item.date!, day)).toList()
      ..sort((a, b) => a.startPeriod!.compareTo(b.startPeriod!));

/// One day's morning and evening reflection.
class JournalEntry {
  const JournalEntry({
    required this.date,
    this.morning = '',
    this.evening = '',
  });

  final DateTime date;
  final String morning;
  final String evening;

  JournalEntry copyWith({String? morning, String? evening}) => JournalEntry(
    date: date,
    morning: morning ?? this.morning,
    evening: evening ?? this.evening,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String().split('T').first,
    'morning': morning,
    'evening': evening,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    date: DateTime.parse(json['date'] as String),
    morning: json['morning'] as String? ?? '',
    evening: json['evening'] as String? ?? '',
  );
}

/// Settings for the morning / evening one-minute reflection.
class ReflectionSettings {
  const ReflectionSettings({
    this.enabled = false,
    this.morningMinutes = 7 * 60 + 10,
    this.eveningMinutes = 21 * 60 + 30,
    this.morningPrompt = defaultMorningPrompt,
    this.eveningPrompt = defaultEveningPrompt,
  });

  static const defaultMorningPrompt = '你今天要做什么？\n最重要的一件事是什么？';
  static const defaultEveningPrompt = '今天的自学完成了几项？\n明天想改什么？';

  final bool enabled;
  final int morningMinutes;
  final int eveningMinutes;
  final String morningPrompt;
  final String eveningPrompt;

  ReflectionSettings copyWith({
    bool? enabled,
    int? morningMinutes,
    int? eveningMinutes,
    String? morningPrompt,
    String? eveningPrompt,
  }) => ReflectionSettings(
    enabled: enabled ?? this.enabled,
    morningMinutes: morningMinutes ?? this.morningMinutes,
    eveningMinutes: eveningMinutes ?? this.eveningMinutes,
    morningPrompt: morningPrompt ?? this.morningPrompt,
    eveningPrompt: eveningPrompt ?? this.eveningPrompt,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'morningMinutes': morningMinutes,
    'eveningMinutes': eveningMinutes,
    'morningPrompt': morningPrompt,
    'eveningPrompt': eveningPrompt,
  };

  factory ReflectionSettings.fromJson(Map<String, dynamic> json) =>
      ReflectionSettings(
        enabled: json['enabled'] as bool? ?? false,
        morningMinutes: json['morningMinutes'] as int? ?? 7 * 60 + 10,
        eveningMinutes: json['eveningMinutes'] as int? ?? 21 * 60 + 30,
        morningPrompt: json['morningPrompt'] as String? ?? defaultMorningPrompt,
        eveningPrompt: json['eveningPrompt'] as String? ?? defaultEveningPrompt,
      );
}

String clockText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
