import 'dart:async';

import 'package:flutter/foundation.dart';

import 'appearance.dart';
import 'custom_event.dart';
import 'island_controller.dart';
import 'models.dart';
import 'notification_service.dart';
import 'plan.dart';
import 'storage.dart';
import 'xls_parser.dart';

/// Everything the app shows, loaded once and persisted on every change.
/// Pages listen to it and call its methods instead of touching storage.
class AppState extends ChangeNotifier {
  AppState({TimetableStorage? storage, NotificationService? notifications})
    : _storage = storage ?? TimetableStorage(),
      _notifications = notifications ?? NotificationService();

  final TimetableStorage _storage;
  final NotificationService _notifications;

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
    reminderMinutes = await _storage.loadReminderMinutes();
    events = await _storage.loadCustomEvents();
    plans = await _storage.loadPlanItems();
    journal = await _storage.loadJournal();
    reflection = await _storage.loadReflection();
    showOtherWeeks = await _storage.loadShowOtherWeeks();
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
    final parsed = XlsParser().parse(bytes);
    timetable = parsed;
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

  Future<void> upsertPlan(PlanItem item) => savePlans([
    for (final plan in plans)
      if (plan.id != item.id) plan,
    item,
  ]);

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
