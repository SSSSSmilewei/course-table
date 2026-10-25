import 'dart:async';

import 'package:flutter/foundation.dart';

import 'appearance.dart';
import 'custom_event.dart';
import 'hiana.dart';
import 'island_controller.dart';
import 'models.dart';
import 'notification_service.dart';
import 'plan.dart';
import 'reminders.dart';
import 'storage.dart';
import 'xls_parser.dart';

/// Everything the app shows, loaded once and persisted on every change.
/// Pages listen to it and call its methods instead of touching storage.
class AppState extends ChangeNotifier {
  AppState({TimetableStorage? storage, NotificationService? notifications, HianaClient? hianaClient})
    : _storage = storage ?? TimetableStorage(),
      _notifications = notifications ?? NotificationService(),
      _hianaClient = hianaClient ?? HianaClient();

  final TimetableStorage _storage;
  final NotificationService _notifications;
  final HianaClient _hianaClient;

  /// 登录的协会账号；为空时不同步，一切照常在本机。
  HianaAccount? hiana;

  bool loading = true;
  Timetable? timetable;
  List<CustomEvent> events = [];
  List<PlanItem> plans = [];
  List<JournalEntry> journal = [];
  int reminderMinutes = 15;
  ReflectionSettings reflection = const ReflectionSettings();
  AppearanceSettings appearance = const AppearanceSettings();
  bool showOtherWeeks = true;

  Future<void> load() async {
    appearance = await _storage.loadAppearance();
    timetable = await _storage.load();
    applySchedule(timetable);
    reminderMinutes = await _storage.loadReminderMinutes();
    events = await _storage.loadCustomEvents();
    plans = await _storage.loadPlanItems();
    journal = await _storage.loadJournal();
    reflection = await _storage.loadReflection();
    showOtherWeeks = await _storage.loadShowOtherWeeks();
    hiana = await HianaClient.loadAccount();
    loading = false;
    notifyListeners();
    await _notifications.initialize();
    if (timetable != null) {
      await _notifications.schedule(timetable!, reminderMinutes);
    }
    await _notifications.scheduleCustomEvents(events);
    await _notifications.scheduleReflection(reflection);
  }

  Future<void> importXls(Uint8List bytes) async {
    // A re-import keeps the user's own schedule (作息时间).
    final previous = timetable;
    final parsed = XlsParser()
        .parse(bytes)
        .copyWith(
          periodStarts: previous?.periodStarts,
          periodLength: previous?.periodLength,
        );
    timetable = parsed;
    applySchedule(parsed);
    notifyListeners();
    await _storage.save(parsed);
    await _notifications.requestPermission();
    await _notifications.schedule(parsed, reminderMinutes);
    unawaited(IslandController().refresh());
  }

  Future<void> updateSemester({DateTime? startDate, int? totalWeeks}) async {
    final current = timetable;
    if (current == null) return;
    timetable = current.copyWith(startDate: startDate, totalWeeks: totalWeeks);
    notifyListeners();
    await _storage.save(timetable!);
    await _notifications.schedule(timetable!, reminderMinutes);
    unawaited(IslandController().refresh());
  }

  /// Saves a custom daily schedule; null [starts] restores the default.
  Future<void> updateSchedule(List<int>? starts, int? length) async {
    final current = timetable;
    if (current == null) return;
    timetable = starts == null
        ? current.copyWith(resetSchedule: true)
        : current.copyWith(periodStarts: starts, periodLength: length);
    applySchedule(timetable);
    notifyListeners();
    await _storage.save(timetable!);
    await _notifications.schedule(timetable!, reminderMinutes);
    unawaited(IslandController().refresh());
  }

  Future<void> setReminderMinutes(int minutes) async {
    reminderMinutes = minutes;
    notifyListeners();
    await _storage.saveReminderMinutes(minutes);
    if (minutes > 0) await _notifications.requestPermission();
    if (timetable != null) await _notifications.schedule(timetable!, minutes);
  }

  Future<void> saveEvents(List<CustomEvent> value) async {
    events = value;
    notifyListeners();
    await _storage.saveCustomEvents(value);
    await _notifications.scheduleCustomEvents(value);
    unawaited(IslandController().refresh());
  }

  Future<void> upsertEvent(CustomEvent event) => saveEvents([
    for (final item in events)
      if (item.id != event.id) item,
    event,
  ]);

  Future<void> deleteEvent(String id) =>
      saveEvents(events.where((item) => item.id != id).toList());

  Future<void> savePlans(List<PlanItem> value) async {
    plans = value;
    notifyListeners();
    await _storage.savePlanItems(value);
  }

  Future<void> upsertPlan(PlanItem item) async {
    final before = plans.where((plan) => plan.id == item.id).toList();
    await savePlans([
      for (final plan in plans)
        if (plan.id != item.id) plan,
      item,
    ]);
    // 协会导入的卡片：完成状态变了就同步过去
    if (item.linked && (before.isEmpty || before.first.done != item.done)) {
      unawaited(_syncUnit(item));
    }
  }

  /* ---------- 协会平台 ---------- */

  /// 最近一次同步失败的原因（页面可以显示）；成功后清空。
  String? hianaError;

  Future<void> _guard(Future<void> Function(HianaAccount account) action) async {
    final account = hiana;
    if (account == null) return;
    try {
      await action(account);
      if (hianaError != null) {
        hianaError = null;
        notifyListeners();
      }
    } on HianaException catch (error) {
      if (error.unauthorized) {
        // 令牌过期或账号被停用：退出，让用户重新登录
        hiana = null;
        await HianaClient.saveAccount(null);
        hianaError = '协会账号已失效，请重新登录';
      } else {
        hianaError = error.message;
      }
      notifyListeners();
    }
  }

  Future<void> _syncUnit(PlanItem item) =>
      _guard((a) => _hianaClient.setUnitDone(a.token, item.hianaCourse!, item.hianaUnit!, item.done));

  Future<void> loginHiana(String studentNo, String password) async {
    final account = await _hianaClient.login(studentNo, password);
    hiana = account;
    hianaError = null;
    notifyListeners();
    await HianaClient.saveAccount(account);
  }

  Future<void> logoutHiana() async {
    hiana = null;
    hianaError = null;
    notifyListeners();
    await HianaClient.saveAccount(null);
  }

  Future<List<HianaCourse>> hianaCourses() {
    final account = hiana;
    if (account == null) throw const HianaException('先登录协会账号');
    return _hianaClient.courses(account.token);
  }

  /// 把协会课程里还没学、也还没导入过的单元，按顺序加到待排的自学卡片里。返回新加了几张。
  Future<int> importHianaCourse(String slug) async {
    final account = hiana;
    if (account == null) throw const HianaException('先登录协会账号');
    final course = await _hianaClient.course(account.token, slug);
    final existing = {
      for (final plan in plans)
        if (plan.hianaCourse == slug && plan.hianaUnit != null) plan.hianaUnit!,
    };
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final group = hianaShortName(course.slug, course.title);
    final added = <PlanItem>[];
    for (final unit in course.units) {
      if (course.done.contains(unit.id) || existing.contains(unit.id)) continue;
      added.add(
        PlanItem(
          id: 'hiana_${stamp}_${added.length}',
          title: unit.title,
          group: group,
          note: '${unit.kindLabel} · ${unit.periods} 课时${unit.note == null ? '' : ' · ${unit.note}'}',
          hianaCourse: slug,
          hianaUnit: unit.id,
        ),
      );
    }
    // 协会那边已经标完成的，本机卡片也勾上
    final next = [
      for (final plan in plans)
        if (plan.hianaCourse == slug && plan.hianaUnit != null && course.done.contains(plan.hianaUnit) && !plan.done)
          plan.copyWith(done: true)
        else
          plan,
      ...added,
    ];
    await savePlans(next);
    return added.length;
  }

  Future<void> deletePlan(String id) =>
      savePlans(plans.where((item) => item.id != id).toList());

  /// Puts [item] on [day] at the given periods, sending whatever card was
  /// there back to the backlog.
  Future<void> placePlan(PlanItem item, DateTime day, int start, int end) {
    final next = <PlanItem>[];
    for (final plan in plans) {
      if (plan.id == item.id) continue;
      final clashes =
          plan.scheduled &&
          sameDate(plan.date!, day) &&
          plan.startPeriod! <= end &&
          plan.endPeriod! >= start;
      next.add(clashes ? plan.unplaced() : plan);
    }
    next.add(item.placed(day, start, end));
    return savePlans(next);
  }

  JournalEntry journalFor(DateTime day) => journal.firstWhere(
    (entry) => sameDate(entry.date, day),
    orElse: () => JournalEntry(date: dateOnly(day)),
  );

  Future<void> saveJournalEntry(JournalEntry entry) async {
    journal = [
      for (final item in journal)
        if (!sameDate(item.date, entry.date)) item,
      entry,
    ]..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _storage.saveJournal(journal);
    // 晨间 / 晚间一分钟写的话，同步成协会的“晨思夜思”
    final day = entry.date.toIso8601String().split('T').first;
    if (entry.morning.isNotEmpty) unawaited(_guard((a) => _hianaClient.putReflection(a.token, day, 'morning', entry.morning)));
    if (entry.evening.isNotEmpty) unawaited(_guard((a) => _hianaClient.putReflection(a.token, day, 'evening', entry.evening)));
  }

  Future<void> setReflection(ReflectionSettings value) async {
    reflection = value;
    notifyListeners();
    await _storage.saveReflection(value);
    if (value.enabled) await _notifications.requestPermission();
    await _notifications.scheduleReflection(value);
  }

  Future<void> setAppearance(AppearanceSettings value) async {
    appearance = value;
    notifyListeners();
    await _storage.saveAppearance(value);
  }

  Future<void> setShowOtherWeeks(bool value) async {
    showOtherWeeks = value;
    notifyListeners();
    await _storage.saveShowOtherWeeks(value);
  }
}
