import 'package:course_table/models.dart';
import 'package:course_table/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

Timetable _table({List<int>? starts, int? length}) => Timetable(
  semester: '',
  className: '',
  startDate: DateTime(2026, 9, 7),
  totalWeeks: 18,
  courses: const [
    Course(
      name: '高等数学 A',
      weekday: 1,
      startPeriod: 1,
      endPeriod: 2,
      weeks: [1, 2, 3],
      campus: '',
      room: '',
      teacher: '',
    ),
  ],
  periodStarts: starts,
  periodLength: length,
);

void main() {
  tearDown(() => applySchedule(null));

  final custom = [
    for (var i = 0; i < 12; i++) 7 * 60 + 50 + i * 55, // 07:50, 08:45, …
  ];

  test('a custom schedule moves course start and end times', () {
    final table = _table(starts: custom, length: 40);
    applySchedule(table);
    final course = table.courses.first;
    final monday = DateTime(2026, 9, 7);
    expect(courseStart(monday, course), DateTime(2026, 9, 7, 7, 50));
    // Ends after period 2 (08:45) plus 40 minutes.
    expect(courseEnd(monday, course), DateTime(2026, 9, 7, 9, 25));
  });

  test('without a custom schedule the defaults apply', () {
    applySchedule(_table());
    expect(periodStartTimes, defaultPeriodStartTimes);
    expect(periodLengthMinutes, defaultPeriodLengthMinutes);
  });

  test('a malformed schedule falls back to the defaults', () {
    applySchedule(_table(starts: [480, 535]));
    expect(periodStartTimes, defaultPeriodStartTimes);
  });

  test('the schedule survives JSON and can be reset', () {
    final table = Timetable.fromJson(
      _table(starts: custom, length: 50).toJson(),
    );
    expect(table.periodStarts, custom);
    expect(table.periodLength, 50);
    final reset = table.copyWith(resetSchedule: true);
    expect(reset.periodStarts, isNull);
    expect(reset.toJson().containsKey('periodStarts'), isFalse);
  });
}
