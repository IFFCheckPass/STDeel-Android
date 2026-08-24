/// 后端 API 客户端 - 思谛 STDeel
///
/// 用 Dio 封装后端 REST 接口。后端仅负责数据库同步：
///   - 用户注册
///   - 解题记录上传 / 反馈更新
///   - 知识点掌握度 / 薄弱知识点
///   - 标准答案库上传 / 匹配
///   - 文件上传
///
/// URL 约定：[AppConfig.defaultBackendUrl] 与设置页输入的后端 URL 视为「完整 API 根」，
/// 含协议、host 与到 API 根的全部前缀路径（如 `https://api.stdeel.com/api/v1`
/// 或反代路径 `https://snserver.dpdns.org/stapi`）。本类只在其后追加资源名
/// （如 `/solve-records`、`/users/register`），不再硬编码 `/api/v1`，以兼容
/// 任意后端路由结构。
library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/ai_combo.dart' show normalizeBaseUrl;

class BackendApi {
  BackendApi({Dio? dio, SharedPreferences? prefs})
      : _dio = dio ?? Dio(),
        _prefsCache = prefs;

  final Dio _dio;
  SharedPreferences? _prefsCache;

  /// 后端 URL（首次访问时从 SharedPreferences 加载）
  ///
  /// 兜底规范化：补全 https://、去尾斜杠、保留子路径（如 /stapi），
  /// 兼容用户直接输入 `snserver.dpdns.org/stapi` 这类历史数据。
  Future<String> _baseUrl() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    final raw =
        _prefsCache!.getString(AppConfig.keyBackendUrl) ??
            AppConfig.defaultBackendUrl;
    return normalizeBaseUrl(raw);
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

  /// AI 组合列表（JSON 数组持久化）
  Future<String?> getAiCombosJson() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!.getString(AppConfig.keyAiCombos);
  }

  Future<void> setAiCombosJson(String json) async {
    _prefsCache ??= await SharedPreferences.getInstance();
    await _prefsCache!.setString(AppConfig.keyAiCombos, json);
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

  /// POST /users/register
  /// 首次启动自动注册，持久化返回的 user_id
  Future<String> registerUser() async {
    final url = '${await _baseUrl()}/users/register';
    try {
      final resp = await _dio.post<dynamic>(
        url,
        data: {'device_id': _deviceId(), 'platform': 'android'},
      );
      // 响应体可能为 null / 非 Map，先判型再取 id，避免首次启动崩溃。
      final data = resp.data;
      final id =
          (data is Map ? (data['user_id'] ?? data['id']) : null)?.toString();
      if (id == null || id.isEmpty) {
        throw BackendApiException('用户注册失败：响应缺少 user_id');
      }
      _prefsCache ??= await SharedPreferences.getInstance();
      await _prefsCache!.setString(AppConfig.keyUserId, id);
      return id;
    } on DioException catch (e) {
      throw BackendApiException('用户注册失败: ${e.message}');
    }
  }

  /// POST /solve-records — 上传解题记录
  Future<void> uploadSolveRecord(Map<String, dynamic> payload) async {
    final url = '${await _baseUrl()}/solve-records';
    payload['user_id'] = await _userId();
    try {
      await _dio.post<dynamic>(url, data: payload);
    } on DioException catch (e) {
      throw BackendApiException('上传解题记录失败: ${e.message}');
    }
  }

  /// PATCH /solve-records/{id}/feedback
  Future<void> updateFeedback(int recordId, String feedback) async {
    final url = '${await _baseUrl()}/solve-records/$recordId/feedback';
    try {
      await _dio.patch<dynamic>(
        url,
        data: {'feedback': feedback, 'user_id': await _userId()},
      );
    } on DioException catch (e) {
      throw BackendApiException('更新反馈失败: ${e.message}');
    }
  }

  /// GET /knowledge/mastery
  Future<List<Map<String, dynamic>>> fetchKnowledgeMastery() async {
    final url = '${await _baseUrl()}/knowledge/mastery';
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

  /// GET /knowledge/weak
  Future<List<Map<String, dynamic>>> fetchWeakKnowledge() async {
    final url = '${await _baseUrl()}/knowledge/weak';
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

  /// POST /answer-library — 上传标准答案
  Future<void> uploadAnswer(Map<String, dynamic> payload) async {
    final url = '${await _baseUrl()}/answer-library';
    payload['user_id'] = await _userId();
    try {
      await _dio.post<dynamic>(url, data: payload);
    } on DioException catch (e) {
      throw BackendApiException('上传标准答案失败: ${e.message}');
    }
  }

  /// POST /answer-library/match — 后端 FTS5 匹配
  /// 返回 {hit: bool, similarity: double, answer?: {...}}
  Future<Map<String, dynamic>> matchAnswer({
    required String questionText,
    required String questionHash,
  }) async {
    final url = '${await _baseUrl()}/answer-library/match';
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

  /// POST /files/upload — 上传图片
  Future<String> uploadImage(String localPath) async {
    final url = '${await _baseUrl()}/files/upload';
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
  ///
  /// 访问后端根 host 的 `/healthz`（而非 API 前缀下的 healthz），
  /// 用于判断「网络可达 + HTTP 服务存活」，与具体 API 路由结构无关。
  /// 任何 2xx/3xx/4xx 响应都视为可达（说明 HTTP 服务起来了），
  /// 仅网络错误或 5xx 视为不通。
  Future<bool> ping() async {
    try {
      final base = await _baseUrl();
      final uri = Uri.tryParse(base);
      // 解析失败或无 host：直接访问 baseUrl 本身探测
      final pingUrl = (uri == null || uri.host.isEmpty)
          ? '$base/healthz'
          : '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/healthz';
      final resp = await _dio.get<dynamic>(
        pingUrl,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final code = resp.statusCode ?? 0;
      return code >= 200 && code < 500;
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
