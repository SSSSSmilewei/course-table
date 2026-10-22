import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import '../plan.dart';
import '../reminders.dart';
import 'common.dart';
import 'glass.dart';
import 'icons.dart';
import 'tokens.dart';

/// 作息时间: when each period starts and how long one lasts. Changes go into
/// the timetable, so reminders, the week grid and the island all follow.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const _lengths = [35, 40, 45, 50, 55, 60];

  int? _editing; // index of the period being edited
  int _picked = 0; // minutes since midnight in the dialog
  String? _error;

  List<int> get _starts => [
    for (final (hour, minute) in periodStartTimes) hour * 60 + minute,
  ];

  void _open(int index) => setState(() {
    _editing = index;
    _picked = _starts[index];
    _error = null;
  });

  void _close() => setState(() => _editing = null);

  /// Periods must stay in order without overlapping.
  String? _validate(List<int> starts, int length) {
    for (var i = 1; i < starts.length; i++) {
      if (starts[i] < starts[i - 1] + length) {
        return '第 $i 节和第 ${i + 1} 节重叠了，后一节要在 ${clockText(starts[i - 1] + length)} 之后开始';
      }
    }
    if (starts.last + length > 24 * 60) return '最后一节要在午夜前结束';
    return null;
  }

  void _savePeriod() {
    final starts = _starts..[_editing!] = _picked;
    final error = _validate(starts, periodLengthMinutes);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    AppScope.read(context).updateSchedule(starts, periodLengthMinutes);
    _close();
  }

  void _setLength(int length) {
    final error = _validate(_starts, length);
    if (error != null) {
      toast('改成 $length 分钟会让课程重叠，请先调整开始时间');
      return;
    }
    AppScope.read(context).updateSchedule(_starts, length);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = Palette(context);
    final starts = _starts;
    final custom = state.timetable?.periodStarts != null;

    // Group by time of day rather than fixed indexes, so any school's
    // schedule reads naturally.
    final groups = <(String, String, List<int>)>[
      ('上午', AppIcons.sunrise, []),
      ('下午', AppIcons.sun, []),
      ('晚上', AppIcons.moon, []),
    ];
    for (var i = 0; i < starts.length; i++) {
      final slot = starts[i] < 12 * 60 ? 0 : (starts[i] < 18 * 60 ? 1 : 2);
      groups[slot].$3.add(i);
    }

    return MiuixScaffold(
      containerColor: const Color(0x00000000),
      topBar: MiuixSmallTopAppBar(
        title: '作息时间',
        subtitle: custom ? '已按你的学校调整' : '默认作息',
        color: const Color(0x00000000),
        navigationIcon: RoundIconButton(
          icon: AppIcons.back,
          label: '返回',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      content: (padding) => Stack(
        children: [
          ListView(
            padding: padding.copyWith(bottom: padding.bottom + 24),
            children: [
              const SizedBox(height: 8),
              PageCard(
                child: MergeSemantics(
                  child: MiuixOverlayDropdownPreference(
                    title: '每节时长',
                    startAction: const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: IconTile(
                        AppIcons.hourglass,
                        color: TileColors.orange,
                      ),
                    ),
                    items: [for (final minutes in _lengths) '$minutes 分钟'],
                    selectedIndex: _lengths
                        .indexOf(periodLengthMinutes)
                        .clamp(0, _lengths.length - 1),
                    onSelectedIndexChange: (index) =>
                        _setLength(_lengths[index]),
                  ),
                ),
              ),
              for (final (label, icon, indexes) in groups)
                if (indexes.isNotEmpty) ...[
                  SectionLabel(label, icon: icon),
                  PageCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.6,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final index in indexes)
                          _PeriodTile(
                            number: index + 1,
                            start: starts[index],
                            length: periodLengthMinutes,
                            onTap: () => _open(index),
                          ),
                      ],
                    ),
                  ),
                ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SecondaryButton(
                  text: '恢复默认作息',
                  icon: AppIcons.undo,
                  onPressed: custom
                      ? () => state.updateSchedule(null, null)
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: Text(
                  '课前提醒、整周课表和超级岛都会按这里的时间走。',
                  style: TypeScale.secondary.copyWith(color: palette.secondary),
                ),
              ),
            ],
          ),
          MiuixOverlayDialog(
            show: _editing != null,
            title: _editing == null ? null : '第 ${_editing! + 1} 节开始时间',
            summary:
                '到 ${clockText(_picked + periodLengthMinutes)} 结束（每节 $periodLengthMinutes 分钟）',
            onDismissRequest: _close,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      child: MiuixNumberPicker(
                        value: _picked ~/ 60,
                        max: 23,
                        wrapAround: true,
                        label: (value) => value.toString().padLeft(2, '0'),
                        onValueChanged: (hour) => setState(() {
                          _picked = hour * 60 + _picked % 60;
                          _error = null;
                        }),
                      ),
                    ),
                    Text(':', style: TypeScale.prompt),
                    SizedBox(
                      width: 96,
                      child: MiuixNumberPicker(
                        value: _picked % 60 ~/ 5,
                        max: 11,
                        wrapAround: true,
                        label: (value) =>
                            (value * 5).toString().padLeft(2, '0'),
                        onValueChanged: (step) => setState(() {
                          _picked = _picked ~/ 60 * 60 + step * 5;
                          _error = null;
                        }),
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TypeScale.secondary.copyWith(
                        color: palette.colors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(text: '取消', onPressed: _close),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: '确定',
                        icon: AppIcons.check,
                        onPressed: _savePeriod,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.number,
    required this.start,
    required this.length,
    required this.onTap,
  });

  final int number;
  final int start;
  final int length;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(context);
    return Tappable(
      onPressed: onTap,
      semanticLabel:
          '第 $number 节，${clockText(start)} 到 ${clockText(start + length)}，点按修改',
      shape: MiuixSquircleBorder(cornerRadius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: palette.tint,
                shape: MiuixSquircleBorder(cornerRadius: 9),
              ),
              child: Text(
                '$number',
                style: TypeScale.chip.copyWith(
                  color: palette.accentText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clockText(start),
                  style: TypeScale.listTitle.copyWith(color: palette.ink),
                ),
                Text(
                  '至 ${clockText(start + length)}',
                  style: TypeScale.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    color: palette.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
