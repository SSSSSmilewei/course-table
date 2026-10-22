import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import '../custom_event.dart';
import '../models.dart';
import '../plan.dart';
import 'common.dart';
import 'tokens.dart';
import 'week_grid.dart';

/// Every week of the semester as one row of tiny day thumbnails, each cell a
/// two-period slot. Tapping a row returns that week to the caller.
class SemesterPage extends StatelessWidget {
  const SemesterPage({super.key});

  static Color _biao(bool dark) => dark ? const Color(0xFF5B8DEF) : const Color(0xFF8FB0F2);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = Palette(context);
    final table = state.timetable!;
    final today = dateOnly(DateTime.now());
    final current = table.rawWeekFor(today);
    final days = visibleWeekdays(table, state.plans);
    final slots = (table.periodCount + 1) ~/ 2;

    var remaining = 0;
    for (var week = current.clamp(1, table.totalWeeks); week <= table.totalWeeks; week++) {
      for (final course in table.coursesForWeek(week)) {
        final date = table.dateFor(week, course.weekday);
        if (date != null && !date.isBefore(today)) remaining += course.endPeriod - course.startPeriod + 1;
      }
    }
    final donePlans = state.plans.where((plan) => plan.done).length;
    final progress = (current.clamp(0, table.totalWeeks) / table.totalWeeks * 100).round();

    Widget stat(String value, String label, {Color? color}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TypeScale.stat.copyWith(color: color ?? palette.ink)),
            Text(label, style: TypeScale.secondary.copyWith(color: palette.secondary)),
          ]),
        );

    return MiuixScaffold(
      topBar: MiuixSmallTopAppBar(
        title: '学期总览',
        subtitle: [
          if (table.semester.isNotEmpty) table.semester,
          if (table.startDate != null) '${table.startDate!.month}/${table.startDate!.day} 开学',
        ].join(' · '),
        navigationIcon: RoundIconButton(
          icon: 'back',
          label: '返回',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      content: (padding) => ListView(
        padding: padding.copyWith(bottom: padding.bottom + 24),
        children: [
          PageCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              stat('${current.clamp(0, table.totalWeeks)} / ${table.totalWeeks}', '学期已过 $progress%'),
              stat('$remaining', '剩余表课节数'),
              stat('$donePlans', '已完成里课', color: palette.accentText),
            ]),
          ),
          const SizedBox(height: 12),
          PageCard(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              children: [
                Row(children: [
                  const SizedBox(width: 64),
                  for (final weekday in days)
                    Expanded(
                      child: Text(weekdayShort[weekday - 1],
                          textAlign: TextAlign.center,
                          style: TypeScale.caption.copyWith(color: palette.secondary)),
                    ),
                ]),
                const SizedBox(height: 4),
                for (var week = 1; week <= table.totalWeeks; week++)
                  _WeekRow(
                    week: week,
                    table: table,
                    plans: state.plans,
                    events: state.events,
                    days: days,
                    slots: slots,
                    isCurrent: week == current,
                    isPast: week < current,
                    biao: _biao(palette.dark),
                  ),
                const SizedBox(height: 10),
                Row(children: [
                  _Legend(color: _biao(palette.dark), label: '表课'),
                  const _Legend(color: Brand.accent, label: '里课'),
                  _Legend(color: palette.colors.error, label: '事件'),
                  const Spacer(),
                  Text('每格两节', style: TypeScale.caption.copyWith(fontWeight: FontWeight.w400, color: palette.secondary)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.table,
    required this.plans,
    required this.events,
    required this.days,
    required this.slots,
    required this.isCurrent,
    required this.isPast,
    required this.biao,
  });

  final int week;
  final Timetable table;
  final List<PlanItem> plans;
  final List<CustomEvent> events;
  final List<int> days;
  final int slots;
  final bool isCurrent;
  final bool isPast;
  final Color biao;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(context);
    final monday = table.dateFor(week, 1);
    final courses = table.coursesForWeek(week);
    Color cell(int weekday, int slot) {
      final first = slot * 2 + 1;
      final date = table.dateFor(week, weekday);
      if (date != null) {
        if (planAt(plans, date, first) != null || planAt(plans, date, first + 1) != null) return Brand.accent;
      }
      final hasCourse = courses.any((course) =>
          course.weekday == weekday && course.startPeriod <= first + 1 && course.endPeriod >= first);
      if (hasCourse) return biao;
      if (date != null && slot == 0 && customEventsForDate(events, date).isNotEmpty) {
        return palette.colors.error;
      }
      return palette.ghostFill;
    }

    return MiuixPressable(
      onPressed: () => Navigator.of(context).pop(week),
      semanticLabel: '第 $week 周',
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: ShapeDecoration(
          color: isCurrent ? palette.tint : const Color(0x00000000),
          shape: MiuixSquircleBorder(cornerRadius: 8),
        ),
        child: Opacity(
          opacity: isPast ? 0.45 : 1,
          child: Row(children: [
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(children: [
                  SizedBox(
                    width: 22,
                    child: Text('$week',
                        style: TypeScale.chip.copyWith(color: isCurrent ? palette.accentText : palette.ink)),
                  ),
                  if (monday != null)
                    Text('${monday.month}/${monday.day}',
                        style: TypeScale.caption.copyWith(fontWeight: FontWeight.w400, color: palette.secondary)),
                ]),
              ),
            ),
            for (final weekday in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: SizedBox(
                    height: 20,
                    child: Row(children: [
                      for (var slot = 0; slot < slots; slot++)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: BoxDecoration(
                              color: cell(weekday, slot),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, right: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(label, style: TypeScale.caption.copyWith(fontWeight: FontWeight.w400, color: Palette(context).secondary)),
        ]),
      );
}
