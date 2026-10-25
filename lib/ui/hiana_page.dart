import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import '../hiana.dart';
import 'common.dart';
import 'icons.dart';
import 'tokens.dart';

/// 协会账号：登录智慧网络算法协会学习平台，导入协会课程的单元当自学卡片，
/// 勾掉卡片、写晨间 / 晚间一分钟时同步过去。
class HianaPage extends StatefulWidget {
  const HianaPage({super.key});

  @override
  State<HianaPage> createState() => _HianaPageState();
}

class _HianaPageState extends State<HianaPage> {
  final _studentNo = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  List<HianaCourse>? _courses;
  String? _importing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppScope.read(context).hiana != null) _loadCourses();
    });
  }

  @override
  void dispose() {
    _studentNo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_studentNo.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = '填上学号和密码');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).loginHiana(_studentNo.text.trim(), _password.text);
      _password.clear();
      await _loadCourses();
    } on HianaException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadCourses() async {
    try {
      final list = await AppScope.read(context).hianaCourses();
      if (mounted) setState(() => _courses = list);
    } on HianaException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _import(HianaCourse course) async {
    setState(() => _importing = course.slug);
    try {
      final n = await AppScope.read(context).importHianaCourse(course.slug);
      toast(n == 0 ? '没有新的单元要导入' : '导入了 $n 个单元，在「自学」里排进课表');
    } on HianaException catch (error) {
      toast(error.message);
    } finally {
      if (mounted) setState(() => _importing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = Palette(context);
    final account = state.hiana;
    return MiuixScaffold(
      containerColor: const Color(0x00000000),
      topBar: MiuixSmallTopAppBar(
        title: '协会账号',
        color: const Color(0x00000000),
        navigationIcon: RoundIconButton(icon: AppIcons.back, label: '返回', onPressed: () => Navigator.of(context).pop()),
      ),
      content: (padding) => ListView(
        padding: padding.copyWith(bottom: padding.bottom + 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 8),
            child: Text(
              '登录智慧网络算法协会学习平台后，可以把协会课程的单元导入成自学卡片；勾掉卡片会同步成协会的学习记录，晨间 / 晚间一分钟写的话会同步成「晨思夜思」。不登录也能正常用。',
              style: TypeScale.secondary.copyWith(color: palette.secondary, height: 20 / 13),
            ),
          ),
          if (state.hianaError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 8),
              child: Text('上次同步没成功：${state.hianaError}', style: TypeScale.secondary.copyWith(color: palette.accentText)),
            ),
          if (account == null) ...[
            const SectionLabel('登录'),
            PageCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MiuixTextField(controller: _studentNo, label: '学号', useLabelAsPlaceholder: true, singleLine: true, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  MiuixTextField(
                    controller: _password,
                    label: '协会平台的密码',
                    useLabelAsPlaceholder: true,
                    singleLine: true,
                    obscureText: true,
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TypeScale.secondary.copyWith(color: palette.accentText)),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(text: _busy ? '正在登录…' : '登录', onPressed: _busy ? null : _login),
                  const SizedBox(height: 10),
                  Text(
                    '第一次用的话，先在网站 study.shanmoew-denied.win 上用会长发的口令激活、设好密码。',
                    style: TypeScale.secondary.copyWith(color: palette.secondary),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SectionLabel('账号'),
            PageCard(
              child: MiuixBasicComponent(
                title: account.name,
                summary: '学号 ${account.studentNo}',
                startAction: const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: IconTile(AppIcons.graduation, color: TileColors.orange),
                ),
              ),
            ),
            const SectionLabel('导入协会课程'),
            if (_courses == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: _error == null ? const MiuixCircularProgressIndicator() : Text(_error!, style: TypeScale.secondary.copyWith(color: palette.secondary))),
              )
            else if (_courses!.where((c) => c.enrolled).isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                child: Text('还没在协会平台选课。先在网站或协会 App 的「课程」里选好，再回来导入。', style: TypeScale.secondary.copyWith(color: palette.secondary)),
              )
            else
              PageCard(
                child: Column(
                  children: [
                    for (final c in _courses!.where((c) => c.enrolled))
                      MiuixArrowPreference(
                        title: hianaShortName(c.slug, c.title),
                        summary: _importing == c.slug ? '正在导入…' : '已学 ${c.doneUnits} / ${c.units} 单元 · 点一下导入没学的单元',
                        onClick: _importing == null ? () => _import(c) : null,
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: Text('导入过的单元不会重复导入；在协会那边已经学完的，这里的卡片也会勾上。', style: TypeScale.secondary.copyWith(color: palette.secondary)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SecondaryButton(text: '退出协会账号', onPressed: () => state.logoutHiana()),
            ),
          ],
        ],
      ),
    );
  }
}
