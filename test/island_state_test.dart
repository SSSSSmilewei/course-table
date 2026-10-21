import 'package:course_table/models.dart';
import 'package:course_table/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 2026-03-04, periods 1-2 (08:00-09:40), weeks 1/3/5 only.
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
    startDate: DateTime(2026, 3, 2), // Monday, week 1
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

  test('courseEnd adds 45 minutes to the last period start', () {
    expect(courseEnd(DateTime(2026, 3, 4), course), DateTime(2026, 3, 4, 9, 40));
    const single = Course(
      name: '体育',
      weekday: 3,
      startPeriod: 1,
      endPeriod: 1,
      weeks: [1],
      campus: '',
      room: '',
      teacher: '',
    );
    expect(courseEnd(DateTime(2026, 3, 4), single), DateTime(2026, 3, 4, 8, 45));
    const last = Course(
      name: '晚自习',
      weekday: 3,
      startPeriod: 12,
      endPeriod: 12,
      weeks: [1],
      campus: '',
      room: '',
      teacher: '',
    );
    expect(courseEnd(DateTime(2026, 3, 4), last), DateTime(2026, 3, 4, 22, 40));
  });

  test('45-minute assumption holds for the whole period table', () {
    for (var i = 0; i < periodStartTimes.length - 1; i++) {
      final current = periodStartTimes[i];
      final next = periodStartTimes[i + 1];
      final endMinutes = current.$1 * 60 + current.$2 + periodLengthMinutes;
      final nextMinutes = next.$1 * 60 + next.$2;
      expect(endMinutes, lessThanOrEqualTo(nextMinutes),
          reason: 'period ${i + 1} must end before period ${i + 2} starts');
    }
  });

  test('currentCourse is null before class starts', () {
    expect(currentCourse(timetable, DateTime(2026, 3, 4, 7, 59)), isNull);
  });

  test('currentCourse hits at start (inclusive) and inside', () {
    expect(currentCourse(timetable, DateTime(2026, 3, 4, 8, 0))?.course.name,
        '离散数学');
    expect(currentCourse(timetable, DateTime(2026, 3, 4, 8, 44))?.course.name,
        '离散数学');
    // Break between periods 1 and 2 is still class time (08:45-08:55).
    expect(currentCourse(timetable, DateTime(2026, 3, 4, 8, 50))?.course.name,
        '离散数学');
  });

  test('currentCourse is null at end (exclusive) and after', () {
    expect(currentCourse(timetable, DateTime(2026, 3, 4, 9, 40)), isNull);
    expect(currentCourse(timetable, DateTime(2026, 3, 4, 12, 0)), isNull);
  });

  test('currentCourse ignores courses in other weeks', () {
    // 2026-03-11 is week 2; the course only occurs in weeks 1/3/5.
    expect(currentCourse(timetable, DateTime(2026, 3, 11, 8, 30)), isNull);
  });

  test('minutesLeft rounds up and clamps at zero', () {
    final current = currentCourse(timetable, DateTime(2026, 3, 4, 8, 0))!;
    expect(current.minutesLeft(DateTime(2026, 3, 4, 9, 0)), 40);
    expect(current.minutesLeft(DateTime(2026, 3, 4, 9, 39, 1)), 1);
    expect(current.minutesLeft(DateTime(2026, 3, 4, 9, 40)), 0);
  });

  test('islandState is IslandInClass during class', () {
    final state = islandState(timetable, DateTime(2026, 3, 4, 8, 30));
    expect(state, isA<IslandInClass>());
    expect((state as IslandInClass).current.course.name, '离散数学');
  });

  test('islandState is IslandUpNext for the next course today', () {
    final state = islandState(timetable, DateTime(2026, 3, 4, 7, 30));
    expect(state, isA<IslandUpNext>());
    expect((state as IslandUpNext).occurrence.start, DateTime(2026, 3, 4, 8));
  });

  test('islandState is IslandUpNext between class end and midnight cutoff', () {
    // After the class ends, the next occurrence is next week — not today.
    expect(islandState(timetable, DateTime(2026, 3, 4, 10, 0)), isNull);
  });

  test('islandState is null when nothing is scheduled today', () {
    expect(islandState(emptyTimetable, DateTime(2026, 3, 4, 8, 30)), isNull);
    // Week 2: the course does not occur, so today has nothing.
    expect(islandState(timetable, DateTime(2026, 3, 11, 7, 30)), isNull);
  });
}
