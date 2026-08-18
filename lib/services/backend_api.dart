/// 后端 API 客户端 - 思谛 STDeel
///
/// 用 Dio 封装后端 REST 接口。后端仅负责数据库同步：
///   - 用户注册
///   - 解题记录上传 / 反馈更新
///   - 知识点掌握度 / 薄弱知识点
///   - 标准答案库上传 / 匹配
///   - 文件上传
library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class BackendApi {
  BackendApi({Dio? dio, SharedPreferences? prefs})
      : _dio = dio ?? Dio(),
        _prefsCache = prefs;

  final Dio _dio;
  SharedPreferences? _prefsCache;

  /// 后端 URL（首次访问时从 SharedPreferences 加载）
  Future<String> _baseUrl() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!.getString(AppConfig.keyBackendUrl) ??
        AppConfig.defaultBackendUrl;
  }

  Future<String> _userId() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    var id = _prefsCache!.getString(AppConfig.keyUserId);
    if (id == null) {
      // 首次启动自动注册
      id = await registerUser();
    }
    return id;
  }

  /// 设置新的后端 URL（用于设置页）
  Future<void> setBackendUrl(String url) async {
    _prefsCache ??= await SharedPreferences.getInstance();
    await _prefsCache!.setString(AppConfig.keyBackendUrl, url);
  }

  Future<void> setApiKeyCombo1(String key) async {
    _prefsCache ??= await SharedPreferences.getInstance();
    await _prefsCache!.setString(AppConfig.keyAiApiKeyCombo1, key);
  }

  Future<void> setApiKeyCombo2(String key) async {
    _prefsCache ??= await SharedPreferences.getInstance();
    await _prefsCache!.setString(AppConfig.keyAiApiKeyCombo2, key);
  }

  Future<String?> getApiKeyCombo1() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!.getString(AppConfig.keyAiApiKeyCombo1);
  }

  Future<String?> getApiKeyCombo2() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!.getString(AppConfig.keyAiApiKeyCombo2);
  }

  Future<int> getThinkTimeoutSeconds() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!.getInt(AppConfig.keyThinkTimeoutSeconds) ??
        AppConfig.defaultThinkTimeoutSeconds;
  }

  Future<void> setThinkTimeoutSeconds(int seconds) async {
    _prefsCache ??= await SharedPreferences.getInstance();
    await _prefsCache!.setInt(AppConfig.keyThinkTimeoutSeconds, seconds);
  }

  Future<String> getBackendUrl() async => _baseUrl();

  /// POST /api/v1/users/register
  /// 首次启动自动注册，持久化返回的 user_id
  Future<String> registerUser() async {
    final url = '${await _baseUrl()}/api/v1/users/register';
    try {
      final resp = await _dio.post<dynamic>(
        url,
        data: {'device_id': _deviceId(), 'platform': 'android'},
      );
      final id = (resp.data['user_id'] ?? resp.data['id']).toString();
      await _prefsCache!.setString(AppConfig.keyUserId, id);
      return id;
    } on DioException catch (e) {
      throw BackendApiException('用户注册失败: ${e.message}');
    }
  }

  /// POST /api/v1/solve-records — 上传解题记录
  Future<void> uploadSolveRecord(Map<String, dynamic> payload) async {
    final url = '${await _baseUrl()}/api/v1/solve-records';
    payload['user_id'] = await _userId();
    try {
      await _dio.post<dynamic>(url, data: payload);
    } on DioException catch (e) {
      throw BackendApiException('上传解题记录失败: ${e.message}');
    }
  }

  /// PATCH /api/v1/solve-records/{id}/feedback
  Future<void> updateFeedback(int recordId, String feedback) async {
    final url =
        '${await _baseUrl()}/api/v1/solve-records/$recordId/feedback';
    try {
      await _dio.patch<dynamic>(
        url,
        data: {'feedback': feedback, 'user_id': await _userId()},
      );
    } on DioException catch (e) {
      throw BackendApiException('更新反馈失败: ${e.message}');
    }
  }

  /// GET /api/v1/knowledge/mastery
  Future<List<Map<String, dynamic>>> fetchKnowledgeMastery() async {
    final url = '${await _baseUrl()}/api/v1/knowledge/mastery';
    try {
      final resp = await _dio.get<dynamic>(
        url,
        queryParameters: {'user_id': await _userId()},
      );
      final list = resp.data['items'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw BackendApiException('获取知识点掌握度失败: ${e.message}');
    }
  }

  /// GET /api/v1/knowledge/weak
  Future<List<Map<String, dynamic>>> fetchWeakKnowledge() async {
    final url = '${await _baseUrl()}/api/v1/knowledge/weak';
    try {
      final resp = await _dio.get<dynamic>(
        url,
        queryParameters: {'user_id': await _userId()},
      );
      final list = resp.data['items'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw BackendApiException('获取薄弱知识点失败: ${e.message}');
    }
  }

  /// POST /api/v1/answer-library — 上传标准答案
  Future<void> uploadAnswer(Map<String, dynamic> payload) async {
    final url = '${await _baseUrl()}/api/v1/answer-library';
    payload['user_id'] = await _userId();
    try {
      await _dio.post<dynamic>(url, data: payload);
    } on DioException catch (e) {
      throw BackendApiException('上传标准答案失败: ${e.message}');
    }
  }

  /// POST /api/v1/answer-library/match — 后端 FTS5 匹配
  /// 返回 {hit: bool, similarity: double, answer?: {...}}
  Future<Map<String, dynamic>> matchAnswer({
    required String questionText,
    required String questionHash,
  }) async {
    final url = '${await _baseUrl()}/api/v1/answer-library/match';
    try {
      final resp = await _dio.post<dynamic>(
        url,
        data: {
          'user_id': await _userId(),
          'question_text': questionText,
          'question_hash': questionHash,
        },
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw BackendApiException('后端答案匹配失败: ${e.message}');
    }
  }

  /// POST /api/v1/files/upload — 上传图片
  Future<String> uploadImage(String localPath) async {
    final url = '${await _baseUrl()}/api/v1/files/upload';
    final form = FormData.fromMap({
      'user_id': await _userId(),
      'file': await MultipartFile.fromFile(localPath),
    });
    try {
      final resp = await _dio.post<dynamic>(url, data: form);
      return (resp.data['url'] ?? resp.data['file_url']).toString();
    } on DioException catch (e) {
      throw BackendApiException('图片上传失败: ${e.message}');
    }
  }

  /// 连通性测试（设置页用）
  Future<bool> ping() async {
    try {
      final resp = await _dio.get<dynamic>(
        '${await _baseUrl()}/healthz',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 简单 device_id（基于 SharedPreferences 持久化的随机串）
  String _deviceId() {
    // 后端可容忍空 device_id 重复注册
    return DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  }
}

class BackendApiException implements Exception {
  const BackendApiException(this.message);
  final String message;

  @override
  String toString() => 'BackendApiException: $message';
}
