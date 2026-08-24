/// 设置状态管理 - 思谛 STDeel
///
/// 管理：
///   - AI 模型组合列表（增删改、排序、启用开关，JSON 持久化）
///   - think 检测超时阈值
///   - 后端 URL 与连通性测试
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/ai_config.dart';
import '../config/app_config.dart';
import '../models/ai_combo.dart';
import '../services/backend_api.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required BackendApi backendApi}) : _api = backendApi;

  final BackendApi _api;

  String _backendUrl = AppConfig.defaultBackendUrl;
  List<AiCombo> _combos = [];
  int _thinkTimeout = AppConfig.defaultThinkTimeoutSeconds;
  bool _pinging = false;
  bool _pingOk = false;
  bool _loaded = false;
  // 账号绑定（默认隐藏）：username 与 api-key 跨端同步，待后端适配后开放。
  String? _username;

  String get backendUrl => _backendUrl;
  List<AiCombo> get combos => List.unmodifiable(_combos);
  int get thinkTimeout => _thinkTimeout;
  bool get pinging => _pinging;
  bool get pingOk => _pingOk;
  bool get loaded => _loaded;
  String? get username => _username;

  /// 已启用且填写完整的组合
  List<AiCombo> get availableCombos =>
      _combos.where((c) => c.enabled && c.isComplete).toList();

  Future<void> load() async {
    _backendUrl = await _api.getBackendUrl();
    _thinkTimeout = await _api.getThinkTimeoutSeconds();
    _username = await _api.getUsername();
    final raw = await _api.getAiCombosJson();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _combos = list
            .map((e) => AiCombo.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _combos = defaultAiCombos();
      }
    } else {
      _combos = defaultAiCombos();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _api.setAiCombosJson(
      jsonEncode(_combos.map((c) => c.toJson()).toList()),
    );
  }

  // ---------- AI 组合管理 ----------

  /// 新增（或更新）组合；id 相同则覆盖
  Future<void> saveCombo(AiCombo combo) async {
    final idx = _combos.indexWhere((c) => c.id == combo.id);
    if (idx >= 0) {
      _combos[idx] = combo;
    } else {
      _combos.add(combo);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteCombo(String id) async {
    _combos.removeWhere((c) => c.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleCombo(String id, bool enabled) async {
    final idx = _combos.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    _combos[idx] = _combos[idx].copyWith(enabled: enabled);
    await _persist();
    notifyListeners();
  }

  /// 拖动排序（ReorderableListView）
  Future<void> moveCombo(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final item = _combos.removeAt(oldIndex);
    _combos.insert(newIndex, item);
    await _persist();
    notifyListeners();
  }

  /// 生成 Failover 调用链（按列表顺序）
  List<AiModelConfig> buildModelChain() =>
      availableCombos.map((c) => c.toModelConfig()).toList();

  // ---------- 通用设置 ----------

  Future<void> setBackendUrl(String url) async {
    _backendUrl = url;
    await _api.setBackendUrl(url);
    notifyListeners();
  }

  Future<void> setThinkTimeout(int seconds) async {
    _thinkTimeout = seconds.clamp(5, 300);
    await _api.setThinkTimeoutSeconds(_thinkTimeout);
    notifyListeners();
  }

  Future<void> ping() async {
    _pinging = true;
    _pingOk = false;
    notifyListeners();
    try {
      _pingOk = await _api.ping();
    } catch (_) {
      _pingOk = false;
    } finally {
      _pinging = false;
      notifyListeners();
    }
  }

  // ---------- 账号绑定（隐藏预埋，后端适配前不暴露到 UI） ----------

  /// 设置用户名：本地持久化，并按 username 尝试绑定后端同一用户。
  /// @return 绑定是否成功（后端未适配 / 网络失败返回 false，但仍保留本地用户名）
  Future<bool> setUsername(String username) async {
    final u = username.trim();
    _username = u;
    await _api.setUsername(u);
    notifyListeners();
    if (u.isNotEmpty && AppConfig.kAccountBindingEnabled) {
      return _api.bindUserByUsername(u);
    }
    return true;
  }
}
