import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import '../custom_event.dart';
import '../models.dart';
import '../plan.dart';
import '../reminders.dart';
import 'actions.dart';
import 'common.dart';
import 'reflection_page.dart';
import 'sheets.dart';
import 'tokens.dart';

/// One row of today's agenda: a 表 course (maybe with a 里 plan inside), a
/// 里 plan in a free slot, or a custom event.
class _AgendaRow {
  _AgendaRow({required this.start, required this.end, this.course, this.plan, this.event});

  final int start; // minutes since midnight
  final int end;
  final Course? course;
  final PlanItem? plan;
  final CustomEvent? event;

  String get title => course?.name ?? event?.title ?? plan!.title;
}

int _periodStart(int period) =>
    periodStartTimes[period - 1].$1 * 60 + periodStartTimes[period - 1].$2;
int _periodEnd(int period) => _periodStart(period) + periodLengthMinutes;

List<_AgendaRow> _agenda(Timetable? table, List<PlanItem> plans, List<CustomEvent> events, DateTime day) {
  final rows = <_AgendaRow>[];
  final dayPlans = plansForDate(plans, day);
  final used = <PlanItem>{};
  for (final course in table?.coursesForDate(day) ?? const <Course>[]) {
    PlanItem? inner;
    for (final plan in dayPlans) {
      if (plan.startPeriod! <= course.endPeriod && plan.endPeriod! >= course.startPeriod) {
        inner = plan;
        used.add(plan);
        break;
      }
    }
    rows.add(_AgendaRow(
      start: _periodStart(course.startPeriod),
      end: _periodEnd(course.endPeriod),
      course: course,
      plan: inner,
    ));
  }
  for (final plan in dayPlans) {
    if (used.contains(plan) || plan.endPeriod! > periodStartTimes.length) continue;
    rows.add(_AgendaRow(start: _periodStart(plan.startPeriod!), end: _periodEnd(plan.endPeriod!), plan: plan));
  }
  for (final event in customEventsForDate(events, day)) {
    rows.add(_AgendaRow(start: event.startMinutes, end: event.endMinutes, event: event));
  }
  return rows..sort((a, b) => a.start.compareTo(b.start));
}

class TodayPage extends StatefulWidget {
  const TodayPage({super.key, required this.onOpenWeek});

  final VoidCallback onOpenWeek;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final _behavior = MiuixExitUntilCollapsedScrollBehavior();
  final _sheet = SheetController();

  @override
  void dispose() {
    _behavior.state.dispose();
    _sheet.dispose();
    super.dispose();
  }

  void _openRow(_AgendaRow row, DateTime today) {
    if (row.course != null) {
      _sheet.open(CourseSheetRequest(row.course!, today));
    } else if (row.event != null) {
      _sheet.open(EventSheetRequest(event: row.event, date: today));
    } else {
      _sheet.open(PlanSheetRequest(row.plan!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = Palette(context);
    final now = DateTime.now();
    final today = dateOnly(now);
    final table = state.timetable;
    final rows = _agenda(table, state.plans, state.events, today);
    final courseCount = rows.where((row) => row.course != null).length;
    final planCount = rows.where((row) => row.plan != null).length;
    final meta = [if (table != null) weekText(table, today), dateLabel(today)].join(' · ');

    return MiuixScaffold(
      containerColor: const Color(0x00000000),
      topBar: MiuixTopAppBar(
        title: '今天',
        scrollBehavior: _behavior,
        actions: [
          RoundIconButton(
            icon: 'add',
            label: '新建事件',
            onPressed: () => _sheet.open(EventSheetRequest(date: today)),
          ),
        ],
      ),
      content: (padding) => Stack(
        children: [
          MiuixScrollBehaviorListener(
            behavior: _behavior,
            child: ListView(
              padding: padding.copyWith(bottom: padding.bottom + 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 12),
                  child: Text(meta, style: TypeScale.secondary.copyWith(color: palette.secondary)),
                ),
                if (state.loading)
                  const SizedBox(height: 200)
                else if (table == null)
                  _ImportCard()
                else ...[
                  _NowCard(rows: rows, table: table, events: state.events),
                  SectionLabel(rows.isEmpty
                      ? '今天没有安排'
                      : '今日 $courseCount 节表课 · $planCount 节里课'),
                  if (rows.isNotEmpty)
                    PageCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          for (final row in rows)
                            _AgendaTile(row: row, now: now, onTap: () => _openRow(row, today)),
                        ],
                      ),
                    )
                  else
                    PageCard(
                      padding: const EdgeInsets.all(16),
                      onPressed: widget.onOpenWeek,
                      child: Text('去「课表」看看这周，或者在「里课」给空课排点东西。',
                          style: TypeScale.secondary.copyWith(color: palette.secondary)),
                    ),
                ],
                const SizedBox(height: 12),
                _ReflectionCard(now: now),
              ],
            ),
          ),
          SheetLayer(controller: _sheet),
        ],
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = Palette(context);
    return PageCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('还没有课表', style: TypeScale.card.copyWith(color: palette.ink)),
          const SizedBox(height: 4),
          Text('在易班或教务系统导出班级课表 .xls，一键导入，不需要学号。',
              style: TypeScale.secondary.copyWith(color: palette.secondary)),
          const SizedBox(height: 16),
          PrimaryButton(text: '导入课表', onPressed: () => importTimetable(context)),
        ],
      ),
    );
  }
}

/// The orange card at the top: what is on now, or what comes next. It ticks
/// on its own so the rest of the page does not rebuild every second.
class _NowCard extends StatefulWidget {
  const _NowCard({required this.rows, required this.table, required this.events});

  final List<_AgendaRow> rows;
  final Timetable table;
  final List<CustomEvent> events;

  @override
  State<_NowCard> createState() => _NowCardState();
}

class _NowCardState extends State<_NowCard> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _now.hour * 60 + _now.minute + _now.second / 60;
    _AgendaRow? current;
    _AgendaRow? next;
    for (final row in widget.rows) {
      if (minutes >= row.start && minutes < row.end) {
        current ??= row;
      } else if (row.start > minutes) {
        next ??= row;
      }
    }

    String badge;
    String time;
    String title;
    String? place;
    PlanItem? inner;
    double? progress;
    String footerLeft;
    String footerRight;
    if (current != null || next != null) {
      final row = (current ?? next)!;
      title = row.course?.name ?? row.event?.title ?? '空课';
      place = row.course == null
          ? row.event?.location
          : [row.course!.room, row.course!.teacher].where((part) => part.isNotEmpty).join(' · ');
      inner = row.plan;
      time = '${clockText(row.start)}–${clockText(row.end)}';
      final periods = row.course != null
          ? '第 ${row.course!.startPeriod}–${row.course!.endPeriod} 节'
          : row.plan != null
              ? '第 ${row.plan!.startPeriod}–${row.plan!.endPeriod} 节'
              : '事件';
      if (current != null) {
        badge = '$periods · 进行中';
        progress = ((minutes - row.start) / (row.end - row.start)).clamp(0.0, 1.0);
        footerLeft = '已过 ${(minutes - row.start).floor()} 分钟';
        footerRight = '还剩 ${(row.end - minutes).ceil()} 分钟';
      } else {
        badge = '$periods · 下一节';
        final wait = Duration(seconds: ((row.start - minutes) * 60).round());
        footerLeft = '距离开始';
        footerRight = countdownText(wait);
      }
    } else {
      final upcoming = nextUp(widget.table, widget.events, _now);
      if (upcoming == null) {
        badge = '今天的课都结束了';
        title = '好好休息';
        time = '';
        footerLeft = '';
        footerRight = '';
      } else {
        badge = '今天的课都结束了';
        title = upcoming.title;
        place = upcoming.location;
        time = '${upcoming.start.month}/${upcoming.start.day} ${weekdayNames[upcoming.start.weekday - 1]} '
            '${clockText(upcoming.start.hour * 60 + upcoming.start.minute)}';
        footerLeft = '下一项';
        footerRight = countdownText(upcoming.start.difference(_now));
      }
    }

    const white = Color(0xFFFFFFFF);
    final dim = const Color(0xFFFFFFFF).withValues(alpha: 0.88);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: ShapeDecoration(color: Brand.hero, shape: MiuixSquircleBorder(cornerRadius: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: ShapeDecoration(
                  color: const Color(0x2EFFFFFF),
                  shape: MiuixSquircleBorder(cornerRadius: 10),
                ),
                child: Text(badge, style: TypeScale.chip.copyWith(color: white)),
              ),
              const Spacer(),
              Text(time, style: TypeScale.secondary.copyWith(color: white)),
            ]),
            const SizedBox(height: 14),
            Text(title, style: TypeScale.stat.copyWith(color: white, height: 32 / 24)),
            if (place != null && place.isNotEmpty)
              Text(place, style: TypeScale.secondary.copyWith(color: dim)),
            if (inner != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                decoration: ShapeDecoration(
                  color: const Color(0x2EFFFFFF),
                  shape: MiuixSquircleBorder(cornerRadius: 12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: ShapeDecoration(color: white, shape: MiuixSquircleBorder(cornerRadius: 6)),
                    child: Text('里', style: TypeScale.chip.copyWith(color: Brand.hero, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(inner.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypeScale.time.copyWith(color: white)),
                  ),
                ]),
              ),
            ],
            if (progress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Stack(children: [
                    Container(color: const Color(0x38FFFFFF)),
                    FractionallySizedBox(widthFactor: progress, child: Container(color: white)),
                  ]),
                ),
              ),
            ],
            if (footerLeft.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Text(footerLeft, style: TypeScale.secondary.copyWith(color: dim)),
                const Spacer(),
                Text(footerRight, style: TypeScale.secondary.copyWith(color: white)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.row, required this.now, required this.onTap});

  final _AgendaRow row;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(context);
    final minutes = now.hour * 60 + now.minute;
    final past = row.end <= minutes;
    final Color bar;
    final String subtitle;
    final String period;
    if (row.course != null) {
      bar = CoursePalette.of(row.course!.name, palette.dark).$2;
      subtitle = [row.course!.room, row.course!.teacher].where((part) => part.isNotEmpty).join(' · ');
      period = '${row.course!.startPeriod}–${row.course!.endPeriod} 节';
    } else if (row.event != null) {
      bar = palette.secondary;
      subtitle = [if (row.event!.location.isNotEmpty) row.event!.location, if (row.event!.weekly) '每周'].join(' · ');
      period = '事件';
    } else {
      bar = Brand.accent;
      subtitle = '空课 · ${row.plan!.group}';
      period = '${row.plan!.startPeriod}–${row.plan!.endPeriod} 节';
    }
    final isFreePlan = row.course == null && row.event == null;
    return MiuixPressable(
      onPressed: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clockText(row.start),
                        style: TypeScale.time.copyWith(color: past ? palette.secondary : palette.ink)),
                    Text(period, style: TypeScale.caption.copyWith(fontWeight: FontWeight.w400, color: palette.secondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 4,
                height: 40,
                decoration: ShapeDecoration(
                  color: past ? palette.ghostFill : bar,
                  shape: MiuixSquircleBorder(cornerRadius: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFreePlan)
                      InnerPlanChip(title: row.plan!.title, done: row.plan!.done)
                    else
                      Text(row.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TypeScale.listTitle.copyWith(color: past ? palette.secondary : palette.ink)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TypeScale.secondary.copyWith(color: palette.secondary)),
                    if (!isFreePlan && row.plan != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InnerPlanChip(title: row.plan!.title, done: row.plan!.done),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = Palette(context);
    final evening = now.hour >= 12;
    final entry = state.journalFor(now);
    final written = evening ? entry.evening : entry.morning;
    final settings = state.reflection;
    final at = clockText(evening ? settings.eveningMinutes : settings.morningMinutes);
    return PageCard(
      onPressed: () => Navigator.of(context).push(SlideRoute((_) => ReflectionPage(evening: evening))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: palette.tint, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: os4Icon(evening ? 'create' : 'alarm', size: 20, tint: palette.accentText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${evening ? '晚间' : '晨间'}一分钟${settings.enabled ? ' · $at' : ''}',
                    style: TypeScale.listTitle.copyWith(color: palette.ink)),
                Text(
                  written.isNotEmpty ? written : (evening ? settings.eveningPrompt : settings.morningPrompt).replaceAll('\n', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TypeScale.secondary.copyWith(color: palette.secondary),
                ),
              ],
            ),
          ),
          os4Icon('chevronForward', size: 18, tint: palette.secondary),
        ],
      ),
    );
  }
}
