import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

import '../models.dart';
import 'common.dart';

/// Picks a Yiban .xls export and imports it, reporting the outcome.
Future<void> importTimetable(BuildContext context) async {
  final state = AppScope.read(context);
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['xls'],
    withData: true,
  );
  final bytes = result?.files.single.bytes;
  if (bytes == null) return;
  try {
    await state.importXls(bytes);
    final table = state.timetable!;
    toast('已导入 ${table.courses.length} 门课'
        '${table.startDate == null ? '，请在设置里填开学日期' : ''}');
  } catch (error) {
    toast('导入失败：${error is FormatException ? error.message : error}');
  }
}

/// "第 8 周", or why there is no teaching week.
String weekText(Timetable table, DateTime date) {
  if (table.startDate == null) return '未设开学日期';
  final week = table.rawWeekFor(date);
  if (week < 1) return '还没开学';
  if (week > table.totalWeeks) return '学期已结束';
  return '第 $week 周';
}
