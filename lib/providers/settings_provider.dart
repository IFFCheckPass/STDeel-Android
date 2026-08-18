/// 设置状态管理 - 思谛 STDeel
library;

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../services/backend_api.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required BackendApi backendApi}) : _api = backendApi;

  final BackendApi _api;

  String _backendUrl = AppConfig.defaultBackendUrl;
  String _apiKeyCombo1 = '';
  String _apiKeyCombo2 = '';
  int _thinkTimeout = AppConfig.defaultThinkTimeoutSeconds;
  bool _pinging = false;
  bool _pingOk = false;

  String get backendUrl => _backendUrl;
  String get apiKeyCombo1 => _apiKeyCombo1;
  String get apiKeyCombo2 => _apiKeyCombo2;
  int get thinkTimeout => _thinkTimeout;
  bool get pinging => _pinging;
  bool get pingOk => _pingOk;

  Future<void> load() async {
    _backendUrl = await _api.getBackendUrl();
    _apiKeyCombo1 = await _api.getApiKeyCombo1() ?? '';
    _apiKeyCombo2 = await _api.getApiKeyCombo2() ?? '';
    _thinkTimeout = await _api.getThinkTimeoutSeconds();
    notifyListeners();
  }

  Future<void> setBackendUrl(String url) async {
    _backendUrl = url;
    await _api.setBackendUrl(url);
    notifyListeners();
  }

  Future<void> setApiKeyCombo1(String key) async {
    _apiKeyCombo1 = key;
    await _api.setApiKeyCombo1(key);
    notifyListeners();
  }

  Future<void> setApiKeyCombo2(String key) async {
    _apiKeyCombo2 = key;
    await _api.setApiKeyCombo2(key);
    notifyListeners();
  }

  Future<void> setThinkTimeout(int seconds) async {
    _thinkTimeout = seconds;
    await _api.setThinkTimeoutSeconds(seconds);
    notifyListeners();
  }

  Future<void> ping() async {
    _pinging = true;
    _pingOk = false;
    notifyListeners();
    _pingOk = await _api.ping();
    _pinging = false;
    notifyListeners();
  }
}
