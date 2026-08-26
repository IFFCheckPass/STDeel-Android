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
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const MethodChannel _channel = MethodChannel('stdeel/updater');

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

  /// 拉取最新 Release 信息。失败抛异常（可读原因）。
  Future<AppUpdateInfo> fetchLatest({
    bool includePrerelease = false,
  }) async {
    final url = includePrerelease
        ? 'https://api.github.com/repos/$kUpdateRepoOwner/$kUpdateRepoName/releases'
        : 'https://api.github.com/repos/$kUpdateRepoOwner/$kUpdateRepoName/releases/latest';
    final resp = await _dio.get<Map<String, dynamic>>(
      url,
      options: Options(
        headers: {'Accept': 'application/vnd.github+json'},
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    final r = resp.data!;
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
    if (!File(dest).existsSync()) throw '下载失败：未生成 APK 文件';
    return dest;
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