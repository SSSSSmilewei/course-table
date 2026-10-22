import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import '../custom_event.dart';
import '../plan.dart';
import 'common.dart';
import 'tokens.dart';

/// One quiet minute: a breathing orb (in 4 s, out 6 s), the day's question
/// and a line to write into the journal. The evening version also lets you
/// tick off today's 里课.
class ReflectionPage extends StatefulWidget {
  const ReflectionPage({super.key, required this.evening});

  final bool evening;

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> with SingleTickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 10));
  late final TextEditingController _text;
  Timer? _timer;
  int _left = 60;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    final entry = state.journalFor(DateTime.now());
    _text = TextEditingController(text: widget.evening ? entry.evening : entry.morning);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_left <= 1) {
        timer.cancel();
        HapticFeedback.mediumImpact();
      }
      setState(() => _left = math.max(0, _left - 1));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "remove animations" switch.
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    _text.dispose();
    super.dispose();
  }

  /// Orb scale over one breath: grow for the first 40 % (inhale), shrink for
  /// the remaining 60 % (exhale).
  double _scale(double t) {
    final eased = t < 0.4
        ? Curves.easeInOut.transform(t / 0.4)
        : 1 - Curves.easeInOut.transform((t - 0.4) / 0.6);
    return 0.72 + 0.28 * eased;
  }

  void _save() {
    final state = AppScope.read(context);
    final entry = state.journalFor(DateTime.now());
    state.saveJournalEntry(widget.evening
        ? entry.copyWith(evening: _text.text.trim())
        : entry.copyWith(morning: _text.text.trim()));
    Navigator.of(context).pop();
    toast('已写进今日日志');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final settings = state.reflection;
    final evening = widget.evening;
    final now = DateTime.now();
    final todayPlans = plansForDate(state.plans, dateOnly(now));
    const cream = Color(0xFFFFF6EE);
    final gradient = evening
        ? const [Color(0xFF120C1E), Color(0xFF2A1630), Color(0xFF4A1E1A)]
        : const [Color(0xFF2B1B13), Color(0xFF8F3508), Color(0xFFF26B1D)];
    final orb = evening
        ? const [Color(0xFFFFB98A), Color(0xFFC2410F), Color(0xFF4A1E1A)]
        : const [Color(0xFFFFF1E6), Color(0xFFFFAA6B), Color(0xFFE2601F)];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradient),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MiuixIconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        backgroundColor: const Color(0x24FFFFFF),
                        child: os4Icon('close', size: 20, tint: cream),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${evening ? '晚间' : '晨间'}一分钟 · ${clockText(now.hour * 60 + now.minute)}',
                      style: TypeScale.secondary.copyWith(color: cream),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      evening ? settings.eveningPrompt : settings.morningPrompt,
                      textAlign: TextAlign.center,
                      style: TypeScale.prompt.copyWith(color: cream),
                    ),
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _breath,
                      builder: (context, _) {
                        final scale = _scale(_breath.value);
                        return SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(alignment: Alignment.center, children: [
                            Transform.scale(
                              scale: 0.8 + (scale - 0.72) * 1.4,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cream.withValues(alpha: 0.06 + (1 - scale) * 0.3),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: scale * 0.8,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: orb),
                                  boxShadow: [BoxShadow(color: orb[1].withValues(alpha: 0.55), blurRadius: 80)],
                                ),
                              ),
                            ),
                            Text('0:${_left.toString().padLeft(2, '0')}',
                                style: TypeScale.timer.copyWith(color: cream)),
                          ]),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _breath,
                      builder: (context, _) => Text(
                        _left == 0 ? '一分钟到了，写下来吧' : (_breath.value < 0.4 ? '吸气 · 4 秒' : '呼气 · 6 秒'),
                        style: TypeScale.listTitle.copyWith(color: cream),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (evening && todayPlans.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('今天的里课', style: TypeScale.section.copyWith(color: cream)),
                      ),
                      const SizedBox(height: 8),
                      for (final plan in todayPlans)
                        MiuixPressable(
                          onPressed: () => state.upsertPlan(plan.copyWith(done: !plan.done)),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              MiuixCheckbox(
                                value: plan.done,
                                onChanged: (value) => state.upsertPlan(plan.copyWith(done: value ?? false)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(plan.title, style: TypeScale.listTitle.copyWith(color: cream)),
                              ),
                              Text('第 ${plan.startPeriod}–${plan.endPeriod} 节',
                                  style: TypeScale.secondary.copyWith(color: cream)),
                            ]),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(evening ? '一句话心得' : '今天最重要的一件事',
                          style: TypeScale.section.copyWith(color: cream)),
                    ),
                    const SizedBox(height: 8),
                    MiuixTextField(
                      controller: _text,
                      label: evening ? '比如：16.01 第 4 讲的控制体积终于懂了' : '比如：学完 16.01 第 4 讲',
                      useLabelAsPlaceholder: true,
                      minLines: 1,
                      maxLines: 4,
                      textStyle: TypeScale.body.copyWith(color: const Color(0xFFFFFFFF)),
                      colors: const MiuixTextFieldColors(
                        backgroundColor: Color(0x1FFFFFFF),
                        labelColor: Color(0xB3FFFFFF),
                        borderColor: Color(0xFFFFF6EE),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: MiuixTextButton(
                          '跳过',
                          onPressed: () => Navigator.of(context).pop(),
                          colors: MiuixButtonColors(
                            color: const Color(0x24FFFFFF),
                            disabledColor: const Color(0x14FFFFFF),
                            contentColor: cream,
                            disabledContentColor: const Color(0x80FFFFFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MiuixTextButton(
                          '写进今日日志',
                          onPressed: _save,
                          colors: MiuixButtonColors(
                            color: cream,
                            disabledColor: const Color(0x80FFF6EE),
                            contentColor: evening ? const Color(0xFF4A1E1A) : const Color(0xFF8F3508),
                            disabledContentColor: const Color(0x808F3508),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
