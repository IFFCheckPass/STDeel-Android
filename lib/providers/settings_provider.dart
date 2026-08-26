/// 设置状态管理 - 思谛 STDeel
///
/// 管理：
///   - AI 模型组合列表（增删改、排序、启用开关，JSON 持久化）
///   - think 检测超时阈值
///   - 后端 URL 与连通性测试
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/ai_config.dart';
import '../config/app_config.dart';
import '../models/ai_combo.dart';
import '../services/backend_api.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required BackendApi backendApi}) : _api = backendApi;

  final BackendApi _api;

  String _publicUrl = AppConfig.defaultBackendUrl;
  String _intranetUrl = '';
  bool _usePublic = true;
  List<AiCombo> _combos = [];
  int _thinkTimeout = AppConfig.defaultThinkTimeoutSeconds;
  bool _pinging = false;
  bool _pingOk = false;
  bool _loaded = false;
  ThemeMode _themeMode = ThemeMode.system;
  // 账号绑定（默认隐藏）：username 与 api-key 跨端同步，待后端适配后开放。
  String? _username;

  /// 当前使用的后端 URL（按所选通道返回，供旧的单一 URL 字段使用）
  String get backendUrl => _usePublic
      ? _publicUrl
      : (_intranetUrl.trim().isEmpty ? _publicUrl : _intranetUrl);
  String get backendUrlPublic => _publicUrl;
  String get backendUrlIntranet => _intranetUrl;
  bool get usePublicBackend => _usePublic;
  List<AiCombo> get combos => List.unmodifiable(_combos);
  int get thinkTimeout => _thinkTimeout;
  bool get pinging => _pinging;
  bool get pingOk => _pingOk;
  bool get loaded => _loaded;
  String? get username => _username;
  ThemeMode get themeMode => _themeMode;

  /// 已启用且填写完整的组合
  List<AiCombo> get availableCombos =>
      _combos.where((c) => c.enabled && c.isComplete).toList();

  Future<void> load() async {
    _publicUrl = await _api.getBackendUrlPublic();
    _intranetUrl = await _api.getBackendUrlIntranet() ?? '';
    _usePublic = await _api.getUsePublicBackend();
    _thinkTimeout = await _api.getThinkTimeoutSeconds();
    _username = await _api.getUsername();
    _themeMode = _parseThemeMode(await _api.getThemeMode());
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
    // 已有绑定用户名时，启动即尝试把本机 AI API Key 上报账号（跨端同步）。
    // fire-and-forget：后端未适配或网络失败时静默，等待下次启动/手动绑定重试。
    if (_username != null && _username!.isNotEmpty) {
      unawaited(_syncAccountApiKeys());
    }
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

  /// 生成 Failover 调用链。
  ///
  /// 排序：支持多模态（视觉/文档识别）的组合稳定排在前面，其余排后，
  /// 使题目 / 文档分析优先使用多模态模型；同组内保持用户在设置页的排列顺序。
  List<AiModelConfig> buildModelChain() {
    final chain = availableCombos.map((c) => c.toModelConfig()).toList();
    if (chain.length > 1) {
      // 稳定分区：multimodal 在前、非 multimodal 在后
      chain.sort((a, b) {
        if (a.multimodal == b.multimodal) return 0;
        return a.multimodal ? -1 : 1;
      });
    }
    return chain;
  }

  // ---------- 通用设置 ----------

  /// 设置当前所选通道（公网或内网）的后端 URL（兼容旧单一 URL 字段）
  Future<void> setBackendUrl(String url) async {
    final normalized = _normalize(url);
    if (_usePublic) {
      _publicUrl = normalized;
      await _api.setBackendUrlPublic(_publicUrl);
    } else {
      _intranetUrl = normalized;
      await _api.setBackendUrlIntranet(_intranetUrl);
    }
    notifyListeners();
  }

  Future<void> setBackendUrlPublic(String url) async {
    _publicUrl = _normalize(url);
    await _api.setBackendUrlPublic(_publicUrl);
    notifyListeners();
  }

  Future<void> setBackendUrlIntranet(String url) async {
    final v = url.trim();
    _intranetUrl = v.isEmpty ? '' : _normalize(v);
    await _api.setBackendUrlIntranet(_intranetUrl);
    notifyListeners();
  }

  /// 切换当前使用公网 / 内网后端
  Future<void> setUsePublicBackend(bool usePublic) async {
    _usePublic = usePublic;
    await _api.setUsePublicBackend(usePublic);
    notifyListeners();
  }

  String _normalize(String url) {
    final t = url.trim();
    if (t.isEmpty) return t;
    var u = t;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Future<void> setThinkTimeout(int seconds) async {
    _thinkTimeout = seconds.clamp(5, 300);
    await _api.setThinkTimeoutSeconds(_thinkTimeout);
    notifyListeners();
  }

  /// 设置主题模式（system / light / dark）
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _api.setThemeMode(_themeModeName(mode));
    notifyListeners();
  }

  String _themeModeName(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  ThemeMode _parseThemeMode(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

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

  /// 把本机已配置且完整的 AI API Key 打包上传到当前绑定账号。
  ///
  /// 后端接口 `PUT /users/api-key`，body `{user_id, api_keys:[{api_key,name,enabled}]}`
  /// 全量覆盖。若接口未适配 / 网络失败则静默失败，由手动绑定流程向用户提示。
  Future<void> _syncAccountApiKeys() async {
    final u = _username;
    if (u == null || u.isEmpty) return;
    final keys = <Map<String, dynamic>>[];
    for (final c in _combos) {
      if (c.isComplete && c.apiKey.trim().isNotEmpty) {
        keys.add({
          'api_key': c.apiKey.trim(),
          'name': c.name,
          'enabled': c.enabled,
        });
      }
    }
    if (keys.isEmpty) return;
    await _api.syncUserApiKeys(keys);
  }

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
