/// 应用内更新服务 - 思谛 STDeel
///
/// 从 GitHub Releases（`IFFCheckPass/STDeel-Android`）拉取最新版本：
///  - 对比本地安装版本，判断是否有新版本
///  - 下载对应 APK 并调用系统安装器安装（原生 MethodChannel 触发）
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'fault_log_service.dart';

/// GitHub 仓库（Release 源）
const String kUpdateRepoOwner = 'IFFCheckPass';
const String kUpdateRepoName = 'STDeel-Android';

/// 拉取的远端版本信息
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.tagName,
    required this.url,
    required this.apkUrl,
    required this.apkSize,
    required this.notes,
    required this.publishedAt,
  });

  /// 远端版本号（不含 v 前缀）
  final String version;

  /// 如 v1.0.0
  final String tagName;

  /// Release 页面链接
  final String url;

  /// APK 直链
  final String apkUrl;

  /// APK 大小（字节）
  final int apkSize;

  /// Release 说明
  final String notes;

  final String publishedAt;

  bool get hasApk => apkUrl.isNotEmpty;

  String get humanApkSize {
    if (apkSize <= 0) return '';
    if (apkSize < 1024 * 1024) return '${(apkSize / 1024).toStringAsFixed(0)} KB';
    return '${(apkSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class UpdateService {
  UpdateService({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  static const MethodChannel _channel = MethodChannel('stdeel/updater');

  /// 构造带统一配置的 Dio：显式 User-Agent（GitHub 对默认/dio 的 UA 可能拒绝，403 的常见诱因）、
  /// 更长的连接/接收超时、主动跟随重定向。
  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'User-Agent': 'STDeel-Android/update-check',
        'Accept': 'application/vnd.github+json',
      },
    ));
    return dio;
  }

  /// 读取当前安装版本号
  static Future<String> currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.0.0';
    }
  }

  /// 简单版本号比较：返回 1 / 0 / -1（a>b / 相等 / a<b）。
  /// 支持形如 `1.0.0`、`0.5.5` 的三段（忽略补丁后的 +build）。
  static int compareVersions(String a, String b) {
    String clean(String s) {
      final i = s.indexOf('+');
      return (i >= 0 ? s.substring(0, i) : s).trim().replaceFirst(RegExp(r'^v'), '');
    }

    final pa = clean(a).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = clean(b).split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x > y ? 1 : -1;
    }
    return 0;
  }

  /// 拉取最新 Release 信息。失败抛异常（可读中文原因）。
  ///
  /// 说明：因版本号 < 1.0.0 发布为 Pre-Release，GitHub 的 `/releases/latest`
  /// 对"只有 pre-release"的仓库会返回 404。因此这里直接拉取 `/releases` 列表，
  /// 取第一项（GitHub 按创建时间倒序），即可拿到最新版本（含 pre-release）。
  Future<AppUpdateInfo> fetchLatest({
    bool includePrerelease = false,
  }) async {
    final listUrl =
        'https://api.github.com/repos/$kUpdateRepoOwner/$kUpdateRepoName/releases';
    try {
      final resp = await _dio.get<List<dynamic>>(
        listUrl,
        queryParameters: {'per_page': 20},
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      final list = resp.data ?? const [];
      Map<String, dynamic>? chosen;
      for (final it in list) {
        if (it is! Map) continue;
        final draft = it['draft'] == true;
        final prerelease = it['prerelease'] == true;
        if (draft) continue;
        if (!includePrerelease && prerelease) continue;
        chosen = Map<String, dynamic>.from(it);
        break;
      }
      if (chosen == null) {
        throw '未找到任何已发布版本';
      }
      return _parseRelease(chosen);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final zh = _zhGithubMessage(code);
      FaultLogService.instance.record(
        source: 'GitHub 更新',
        code: code != null ? '$code' : '网络',
        summary: zh,
      );
      throw code == 404
          ? '检查更新失败：GitHub 未找到该仓库的发布（HTTP 404）'
          : code == 403
              ? '检查更新失败：GitHub 访问受限（HTTP 403，多为请求过于频繁被限流）'
              : code == 429
                  ? '检查更新失败：GitHub 触发限流（HTTP 429），请稍后再试'
                  : '检查更新失败：$zh';
    } catch (e) {
      throw '检查更新失败：$e';
    }
  }

  /// 把单个 release JSON 解析为 [AppUpdateInfo]
  AppUpdateInfo _parseRelease(Map<String, dynamic> r) {
    final tag = (r['tag_name'] ?? '').toString();
    final assets = (r['assets'] as List<dynamic>?) ?? const [];
    String apkUrl = '';
    int apkSize = 0;
    for (final a in assets) {
      if (a is Map && (a['name'] ?? '').toString().toLowerCase().endsWith('.apk')) {
        if (apkUrl.isEmpty) {
          apkUrl = (a['browser_download_url'] ?? '').toString();
          apkSize = (a['size'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return AppUpdateInfo(
      version: tag.replaceFirst(RegExp(r'^v'), ''),
      tagName: tag,
      url: (r['html_url'] ?? '').toString(),
      apkUrl: apkUrl,
      apkSize: apkSize,
      notes: (r['body'] ?? '').toString(),
      publishedAt: (r['published_at'] ?? '').toString(),
    );
  }

  /// GitHub 常见 HTTP 状态码 → 中文说明
  String _zhGithubMessage(int? code) {
    switch (code) {
      case 403:
        return '访问被拒绝（HTTP 403）——通常为 GitHub API 未带 Token 触发限流，'
            '或所在网络对 api.github.com 有限制，请稍后再试';
      case 404:
        return '资源不存在（HTTP 404）——Release 版本或指定位被移除，'
            '或仓库不可见';
      case 429:
        return '爬取过于频繁（HTTP 429）——已触发限流，请稍后再试';
      case 500:
        return 'GitHub 服务器错误（HTTP 500）';
      case 502:
        return '网关错误（HTTP 502）';
      case 503:
        return '服务暂不可用（HTTP 503）';
      default:
        return code == null ? '网络连接失败，无法访问 GitHub' : 'GitHub 请求失败（HTTP $code）';
    }
  }

  /// 检查是否有可用更新。
  /// @return 有更新返回 [AppUpdateInfo]；无返回 null（抛错则说明无法检查）。
  Future<AppUpdateInfo?> checkForUpdate() async {
    final latest = await fetchLatest();
    final current = await currentVersion();
    if (compareVersions(latest.version, current) <= 0) return null;
    return latest;
  }

  /// 下载 APK 到缓存目录（返回本地路径），带进度回调。
  Future<String> downloadApk(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final dest = p.join(dir.path, 'stdeel_update_${DateTime.now().millisecondsSinceEpoch}.apk');
    try {
      await _dio.download(
        url,
        dest,
        onReceiveProgress: (received, total) =>
            onProgress?.call(received, total),
        options: Options(
          receiveTimeout: const Duration(minutes: 2),
          followRedirects: true,
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final zh = _zhGithubMessage(code ?? (e.type == DioExceptionType.connectionError ? null : code));
      FaultLogService.instance.record(
        source: 'GitHub 更新下载',
        code: code != null ? '$code' : (e.type == DioExceptionType.connectionError ? '网络' : '未知'),
        summary: e.type == DioExceptionType.connectionError
            ? '下载文件网络连接失败'
            : zh,
      );
      throw '更新包下载失败：${_zhDownloadMessage(e)}';
    }
    if (!File(dest).existsSync()) throw '下载失败：未生成 APK 文件';
    return dest;
  }

  String _zhDownloadMessage(DioException e) {
    final code = e.response?.statusCode;
    if (code == 403) return '下载被拒绝（HTTP 403），多为下载地址被限流或网络限制';
    if (code == 404) return '下载地址不存在（HTTP 404），版本包可能已被移除';
    if (code == 429) return '下载触发限流（HTTP 429），请稍后再试';
    if (e.type == DioExceptionType.connectionError) return '网络连接中断，请检查网络后重试';
    if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return '下载超时';
    }
    return code != null ? 'HTTP $code' : (e.message ?? '未知错误');
  }

  /// 触发系统安装器安装（原生 MethodChannel）。
  /// 需用户授权"安装未知来源应用"。
  Future<void> installApk(String path) async {
    try {
      await _channel.invokeMethod<void>('installApk', {'path': path});
    } on PlatformException catch (e) {
      throw '安装失败：${e.message ?? e.code}';
    }
  }
}