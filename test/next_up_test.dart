import 'package:course_table/custom_event.dart';
import 'package:course_table/models.dart';
import 'package:course_table/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const course = Course(
    name: '离散数学',
    weekday: 3,
    startPeriod: 1,
    endPeriod: 2,
    weeks: [1, 3, 5],
    campus: '校本部',
    room: '八教202',
    teacher: '刘老师',
  );
  final timetable = Timetable(
    semester: '2025-2026年第2学期',
    className: '计科2502',
    startDate: DateTime(2026, 3, 2),
    totalWeeks: 20,
    courses: const [course],
  );
  final emptyTimetable = Timetable(
    semester: '',
    className: '',
    startDate: DateTime(2026, 3, 2),
    totalWeeks: 20,
    courses: const [],
  );

  CustomEvent eventAt(int startMinutes) => CustomEvent(
    id: 'e1',
    title: '班会',
    location: '教学楼101',
    date: DateTime(2026, 3, 4),
    startMinutes: startMinutes,
    endMinutes: startMinutes + 45,
    weekly: false,
    reminderMinutes: 10,
  );

  test('returns the next course when there are no events', () {
    final up = nextUp(timetable, const [], DateTime(2026, 3, 4, 7, 30));
    expect(up?.title, '离散数学');
    expect(up?.location, '八教202');
    expect(up?.start, DateTime(2026, 3, 4, 8));
  });

  test('an event starting before the course wins', () {
    final up = nextUp(timetable, [
      eventAt(7 * 60 + 45),
    ], DateTime(2026, 3, 4, 7, 30));
    expect(up?.title, '班会');
    expect(up?.location, '教学楼101');
    expect(up?.start, DateTime(2026, 3, 4, 7, 45));
  });

  test('the course wins when it starts before the event', () {
    final up = nextUp(timetable, [
      eventAt(9 * 60),
    ], DateTime(2026, 3, 4, 7, 30));
    expect(up?.title, '离散数学');
  });

  test('the course wins when course and event start at the same time', () {
    final up = nextUp(timetable, [
      eventAt(8 * 60),
    ], DateTime(2026, 3, 4, 7, 30));
    expect(up?.title, '离散数学');
  });

  test('returns an event when the timetable has no courses', () {
    final up = nextUp(emptyTimetable, [
      eventAt(9 * 60),
    ], DateTime(2026, 3, 4, 8, 30));
    expect(up?.title, '班会');
  });

  test('returns null when nothing is upcoming', () {
    final up = nextUp(timetable, const [], DateTime(2026, 6, 1, 12));
    expect(up, isNull);
  });
}
