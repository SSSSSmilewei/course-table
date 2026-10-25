import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// 智慧网络算法协会（HIANA）学习平台的账号连接。
///
/// 课表 App 和协会平台是两个独立的仓库；登录协会账号后，这里可以：
///  - 把协会课程里还没学的单元导入成里课表的自学卡片；
///  - 勾掉这些卡片时，同步标记协会课程的单元完成（计入协会热力图的“站内学习”）；
///  - 晨间 / 晚间一分钟写完后同步成协会的“晨思夜思”。
///
/// 不登录也完全能用，所有数据仍然先存在本机；同步失败只提示，不影响本地。
const hianaBaseUrl = String.fromEnvironment('HIANA_API', defaultValue: 'https://study.shanmoew-denied.win');

class HianaException implements Exception {
  const HianaException(this.message, {this.status});
  final String message;
  final int? status;

  bool get unauthorized => status == 401;

  @override
  String toString() => message;
}

class HianaAccount {
  const HianaAccount({required this.token, required this.name, required this.studentNo});
  final String token;
  final String name;
  final String studentNo;

  Map<String, dynamic> toJson() => {'token': token, 'name': name, 'studentNo': studentNo};

  factory HianaAccount.fromJson(Map<String, dynamic> json) => HianaAccount(
        token: json['token'] as String,
        name: json['name'] as String? ?? '',
        studentNo: json['studentNo'] as String? ?? '',
      );
}

/// 协会课程里的一个单元。
class HianaUnit {
  const HianaUnit({required this.id, required this.title, required this.kind, required this.periods, this.note});
  final String id;
  final String title;
  final String kind; // lecture | pset | practice | reading | project
  final int periods;
  final String? note;

  String get kindLabel =>
      const {'lecture': '讲座', 'pset': '习题', 'practice': '练习', 'reading': '阅读', 'project': '项目'}[kind] ?? kind;
}

class HianaCourse {
  const HianaCourse({
    required this.slug,
    required this.title,
    required this.enrollStatus,
    required this.doneUnits,
    required this.units,
  });
  final String slug;
  final String title;
  final String? enrollStatus; // active | paused | done | dropped | null
  final int doneUnits;
  final int units;

  bool get enrolled => enrollStatus == 'active' || enrollStatus == 'paused';
}

class HianaCourseDetail {
  const HianaCourseDetail({required this.slug, required this.title, required this.units, required this.done});
  final String slug;
  final String title;
  final List<HianaUnit> units;
  final Set<String> done;
}

/// 卡片上显示的短名，例如 "CS50x"、"Missing Semester"。
String hianaShortName(String slug, String title) =>
    const {
      'missing-semester': 'Missing Semester',
      'git': 'Git',
      'cs50x': 'CS50x',
      'cs50p': 'CS50P',
      'cs61a': 'CS61A',
      'mit-1801': 'MIT 18.01',
    }[slug] ??
    title;

class HianaClient {
  HianaClient({String baseUrl = hianaBaseUrl, HttpClient? http})
      : _base = Uri.parse(baseUrl),
        _http = http ?? (HttpClient()..connectionTimeout = const Duration(seconds: 10));

  final Uri _base;
  final HttpClient _http;

  static const _key = 'hianaAccount';

  static Future<HianaAccount?> loadAccount() async {
    final value = (await SharedPreferences.getInstance()).getString(_key);
    if (value == null) return null;
    try {
      return HianaAccount.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  static Future<void> saveAccount(HianaAccount? account) async {
    final preferences = await SharedPreferences.getInstance();
    if (account == null) {
      await preferences.remove(_key);
    } else {
      await preferences.setString(_key, jsonEncode(account.toJson()));
    }
  }

  Future<Object?> _send(String method, String path, {String? token, Object? body}) async {
    final HttpClientResponse res;
    final String text;
    try {
      final req = await _http.openUrl(method, _base.resolve(path));
      req.headers.set('X-Hiana-Client', 'app');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null) req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(jsonEncode(body)));
      }
      res = await req.close().timeout(const Duration(seconds: 20));
      text = await res.transform(utf8.decoder).join();
    } on SocketException {
      throw const HianaException('连不上协会平台，检查一下网络');
    } on HandshakeException {
      throw const HianaException('连不上协会平台，检查一下网络');
    } on HttpException {
      throw const HianaException('连不上协会平台，检查一下网络');
    } on Exception {
      throw const HianaException('连接协会平台超时，稍后再试');
    }
    Object? data;
    try {
      data = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      data = null;
    }
    if (res.statusCode >= 400) {
      final message = data is Map && data['error'] is String ? data['error'] as String : '协会平台返回了错误（${res.statusCode}）';
      throw HianaException(message, status: res.statusCode);
    }
    return data;
  }

  /// 学号 + 协会平台上自己设的密码。第一次用要先在网站上用会长发的口令激活、设好密码。
  Future<HianaAccount> login(String studentNo, String password) async {
    final data = await _send('POST', '/api/auth/member', body: {'studentNo': studentNo, 'password': password});
    if (data is! Map || data['token'] is! String) {
      throw const HianaException('协会平台没有返回登录令牌，可能还没更新到支持 App 的版本');
    }
    final member = data['member'] as Map? ?? const {};
    return HianaAccount(
      token: data['token'] as String,
      name: member['name'] as String? ?? '',
      studentNo: member['studentNo'] as String? ?? studentNo,
    );
  }

  Future<List<HianaCourse>> courses(String token) async {
    final data = await _send('GET', '/api/courses', token: token);
    return [
      for (final c in (data as List? ?? const []).cast<Map<String, dynamic>>())
        HianaCourse(
          slug: c['slug'] as String,
          title: c['title'] as String,
          enrollStatus: (c['enrollment'] as Map?)?['status'] as String?,
          doneUnits: ((c['progress'] as Map?)?['doneUnits'] as num? ?? 0).toInt(),
          units: ((c['progress'] as Map?)?['units'] as num? ?? 0).toInt(),
        ),
    ];
  }

  Future<HianaCourseDetail> course(String token, String slug) async {
    final data = await _send('GET', '/api/courses/$slug', token: token) as Map<String, dynamic>;
    final c = data['course'] as Map<String, dynamic>;
    return HianaCourseDetail(
      slug: c['slug'] as String,
      title: c['title'] as String,
      units: [
        for (final u in (c['units'] as List).cast<Map<String, dynamic>>())
          HianaUnit(
            id: u['id'] as String,
            title: u['title'] as String,
            kind: u['kind'] as String? ?? 'lecture',
            periods: (u['periods'] as num? ?? 0).toInt(),
            note: u['note'] as String?,
          ),
      ],
      done: (data['done'] as Map? ?? const {}).keys.cast<String>().toSet(),
    );
  }

  Future<void> setUnitDone(String token, String slug, String unitId, bool done) =>
      _send('PUT', '/api/courses/$slug/units/$unitId', token: token, body: {'done': done});

  /// [day] 是 "2026-10-25"，[slot] 是 morning 或 evening。
  Future<void> putReflection(String token, String day, String slot, String text) =>
      _send('PUT', '/api/reflections/$day/$slot', token: token, body: {'text': text, 'source': 'course-table'});
}
