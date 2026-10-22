import 'package:course_table/app_state.dart';
import 'package:course_table/plan.dart';
import 'package:course_table/storage.dart';
import 'package:course_table/ui/sheets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final day = DateTime(2026, 10, 22);

  test('a placed card occupies only its own periods on its own day', () {
    final card = const PlanItem(id: 'a', title: '16.01 L4', group: 'MIT 16.01').placed(day, 3, 4);
    expect(card.occupies(day, 3), isTrue);
    expect(card.occupies(day, 4), isTrue);
    expect(card.occupies(day, 5), isFalse);
    expect(card.occupies(day.add(const Duration(days: 1)), 3), isFalse);
    expect(planAt([card], day, 4), card);
  });

  test('sending an unfinished card back counts a deferral, a finished one does not', () {
    final placed = const PlanItem(id: 'a', title: 'x', group: '').placed(day, 1, 2);
    expect(placed.unplaced().deferCount, 1);
    expect(placed.unplaced().scheduled, isFalse);
    expect(placed.copyWith(done: true).unplaced().deferCount, 0);
  });

  test('plans round-trip through JSON', () {
    final card = const PlanItem(id: 'a', title: 'PSet 1', group: 'MIT 16.01', deferCount: 2)
        .placed(day, 5, 6);
    final copy = PlanItem.fromJson(card.toJson());
    expect(copy.title, 'PSet 1');
    expect(copy.date, day);
    expect(copy.startPeriod, 5);
    expect(copy.deferCount, 2);
  });

  test('placing a card on an occupied slot sends the old card back', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(storage: TimetableStorage());
    final old = const PlanItem(id: 'old', title: 'old', group: '').placed(day, 3, 4);
    const fresh = PlanItem(id: 'new', title: 'new', group: '');
    state.plans = [old, fresh];
    await state.placePlan(fresh, day, 3, 4);
    final byId = {for (final plan in state.plans) plan.id: plan};
    expect(byId['new']!.occupies(day, 3), isTrue);
    expect(byId['old']!.scheduled, isFalse);
    expect(byId['old']!.deferCount, 1);
  });

  test('week lists collapse into ranges', () {
    expect(weekRangesText([1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14]), '第 1–8、10、12、14 周');
    expect(weekRangesText([9]), '第 9 周');
  });

  test('reflection settings keep custom prompts through JSON', () {
    const settings = ReflectionSettings(enabled: true, morningPrompt: '今天学什么？');
    final copy = ReflectionSettings.fromJson(settings.toJson());
    expect(copy.enabled, isTrue);
    expect(copy.morningPrompt, '今天学什么？');
    expect(copy.eveningPrompt, ReflectionSettings.defaultEveningPrompt);
  });
}
