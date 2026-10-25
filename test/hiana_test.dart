import 'package:course_table/app_state.dart';
import 'package:course_table/hiana.dart';
import 'package:course_table/plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeClient extends HianaClient {
  final synced = <String>[];
  final reflections = <String>[];

  @override
  Future<HianaCourseDetail> course(String token, String slug) async => const HianaCourseDetail(
        slug: 'git',
        title: 'Git 版本管理',
        units: [
          HianaUnit(id: 'concept', title: '为什么需要版本管理', kind: 'reading', periods: 1),
          HianaUnit(id: 'lgb-basic', title: '可视化练习：提交与分支', kind: 'practice', periods: 2),
          HianaUnit(id: 'first-repo', title: '在 Gitee 上建第一个仓库', kind: 'practice', periods: 2),
        ],
        done: {'concept'},
      );

  @override
  Future<void> setUnitDone(String token, String slug, String unitId, bool done) async => synced.add('$slug/$unitId=$done');

  @override
  Future<void> putReflection(String token, String day, String slot, String text) async => reflections.add('$slot:$text');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('协会卡片的关联信息在排课、退回和序列化后都保留', () {
    const card = PlanItem(id: 'a', title: 'x', group: 'Git', hianaCourse: 'git', hianaUnit: 'lgb-basic');
    final placed = card.placed(DateTime(2026, 10, 22), 3, 4);
    expect(placed.linked, isTrue);
    expect(placed.unplaced().hianaUnit, 'lgb-basic');
    expect(placed.copyWith(done: true).hianaCourse, 'git');
    final back = PlanItem.fromJson(placed.toJson());
    expect(back.hianaCourse, 'git');
    expect(back.hianaUnit, 'lgb-basic');
    expect(PlanItem.fromJson(const PlanItem(id: 'b', title: 'y', group: '').toJson()).linked, isFalse);
  });

  test('导入跳过已学完和已导入的单元，勾掉卡片会同步到协会', () async {
    final client = _FakeClient();
    final state = AppState(hianaClient: client)..hiana = const HianaAccount(token: 't', name: '林同学', studentNo: '1');
    expect(await state.importHianaCourse('git'), 2);
    expect(state.plans.map((p) => p.hianaUnit), ['lgb-basic', 'first-repo']);
    expect(await state.importHianaCourse('git'), 0); // 不重复导入

    await state.upsertPlan(state.plans.first.copyWith(done: true));
    await Future<void>.delayed(Duration.zero);
    expect(client.synced, ['git/lgb-basic=true']);

    // 改标题不算完成状态变化，不同步
    await state.upsertPlan(state.plans.firstWhere((p) => p.hianaUnit == 'first-repo').copyWith(title: '建仓库'));
    await Future<void>.delayed(Duration.zero);
    expect(client.synced, hasLength(1));
  });

  test('没登录协会账号时什么都不同步', () async {
    final client = _FakeClient();
    final state = AppState(hianaClient: client);
    await state.upsertPlan(const PlanItem(id: 'a', title: 'x', group: '', hianaCourse: 'git', hianaUnit: 'concept', done: true));
    await state.saveJournalEntry(JournalEntry(date: DateTime(2026, 10, 25), morning: '学 Git'));
    await Future<void>.delayed(Duration.zero);
    expect(client.synced, isEmpty);
    expect(client.reflections, isEmpty);
  });

  test('晨间一分钟写的话同步成晨思夜思', () async {
    final client = _FakeClient();
    final state = AppState(hianaClient: client)..hiana = const HianaAccount(token: 't', name: '林同学', studentNo: '1');
    await state.saveJournalEntry(JournalEntry(date: DateTime(2026, 10, 25), morning: '先做习题集 1'));
    await Future<void>.delayed(Duration.zero);
    expect(client.reflections, ['morning:先做习题集 1']);
  });
}
