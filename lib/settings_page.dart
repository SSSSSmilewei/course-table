import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'appearance.dart';
import 'island_controller.dart';
import 'notification_service.dart';
import 'platform_capabilities.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.appearance, required this.onChanged});
  final AppearanceSettings appearance;
  final ValueChanged<AppearanceSettings> onChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  late AppearanceSettings appearance = widget.appearance;
  final _island = IslandController();
  bool _islandEnabled = false;
  IslandCapability? _capability;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshIslandStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have flipped the focus-notification switch in system
    // settings, so re-read the capability whenever we come back.
    if (state == AppLifecycleState.resumed) _refreshIslandStatus();
  }

  Future<void> _refreshIslandStatus() async {
    if (!supportsSystemIsland()) return;
    final enabled = await _island.isEnabled();
    final capability = await _island.capability();
    if (mounted) {
      setState(() {
        _islandEnabled = enabled;
        _capability = capability;
      });
    }
  }

  Future<void> _toggleIsland(bool value) async {
    if (!value) {
      await _island.stop();
      await _refreshIslandStatus();
      return;
    }
    await NotificationService().requestPermission();
    await _island.start();
    final capability = await _island.capability();
    await _refreshIslandStatus();
    if (capability == null || capability.hasFocusPermission || !mounted) return;
    await _showIslandPermissionDialog(capability);
  }

  /// Opens a system settings page, telling the user when the device has no
  /// activity for it instead of failing silently.
  Future<void> _openSystemSettings(
    Future<bool> Function() open,
    String failure,
  ) async {
    final opened = await open();
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
  }

  Future<void> _showIslandPermissionDialog(IslandCapability capability) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('让灵动岛生效'),
        content: Text(
          '${capability.description}。\n\n'
          '想要显示成灵动岛，需要在系统里完成以下设置：\n'
          '· 通知权限：允许 CourseTable 发送通知\n'
          '· 焦点通知：在「通知管理」里打开 CourseTable 的焦点通知\n'
          '· 自启动：允许 CourseTable 自启动\n'
          '· 省电策略：设为「无限制」\n\n'
          '焦点通知需要小米侧开通白名单，未开通时通知会以普通形式显示。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openSystemSettings(
                _island.openAutostartSettings,
                '无法打开自启动设置,请手动到系统设置里允许自启动',
              );
            },
            child: const Text('小米:开启自启动'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openSystemSettings(_island.openNotificationSettings, '无法打开通知设置');
            },
            child: const Text('打开通知设置'),
          ),
        ],
      ),
    );
  }

  void _update(AppearanceSettings value) {
    setState(() => appearance = value);
    widget.onChanged(value);
  }

  Future<void> _chooseBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/course_table_background.jpg');
    await file.writeAsBytes(bytes, flush: true);
    _update(appearance.copyWith(backgroundPath: file.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          if (supportsSystemIsland()) ...[
            const ListTile(title: Text('灵动岛', style: TextStyle(fontWeight: FontWeight.bold))),
            SwitchListTile(
              value: _islandEnabled,
              title: const Text('系统灵动岛'),
              subtitle: Text(
                !_islandEnabled ? '已关闭' : (_capability?.description ?? '运行中'),
              ),
              onChanged: _toggleIsland,
            ),
            if (_islandEnabled && _capability != null && !_capability!.hasFocusPermission)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('打开通知设置'),
                subtitle: const Text('开启焦点通知权限后才会显示灵动岛'),
                onTap: () => _openSystemSettings(
                  _island.openNotificationSettings,
                  '无法打开通知设置',
                ),
              ),
            const Divider(),
          ],
          const ListTile(title: Text('显示', style: TextStyle(fontWeight: FontWeight.bold))),
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              value: mode,
              groupValue: appearance.themeMode,
              title: Text(switch (mode) {
                ThemeMode.system => '跟随系统',
                ThemeMode.light => '浅色模式',
                ThemeMode.dark => '深色模式',
              }),
              onChanged: (value) => _update(appearance.copyWith(themeMode: value)),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('选择背景图片'),
            subtitle: Text(appearance.backgroundPath == null ? '未设置' : '已设置'),
            onTap: _chooseBackground,
          ),
          if (appearance.backgroundPath != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('移除背景图片'),
              onTap: () => _update(appearance.copyWith(removeBackground: true)),
            ),
          ListTile(
            title: const Text('背景可见度'),
            subtitle: Slider(
              value: appearance.backgroundOpacity,
              min: 0.05,
              max: 0.8,
              divisions: 15,
              label: '${(appearance.backgroundOpacity * 100).round()}%',
              onChanged: (value) => _update(appearance.copyWith(backgroundOpacity: value)),
            ),
          ),
        ],
      ),
    );
  }
}
