/// 图片缓存服务 - 思谛 STDeel
///
/// 目标：重答 / 疑问时能把"原始拍摄图片"（含完整题干选项 / 图表）重新交给 AI，
/// 避免出现「重答丢失选项 / 图表无法识别」等产品级问题。
///
/// 实现：
///  - 把拍摄/裁切后的图片从临时目录复制到应用文档目录下的持久缓存
///    `question_cache/`，使其在重答期间依然可用（OS 的临时目录可能随时被清掉）。
///  - 启动时按文件修改时间清理超过 [maxRetentionDays]（默认 15 天）的缓存图。
///  - 提供手动「清除图片缓存」入口。
library;

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCacheStats {
  const ImageCacheStats({required this.count, required this.sizeBytes});

  /// 缓存图片数量
  final int count;

  /// 缓存占用字节
  final int sizeBytes;

  String get humanSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ImageCacheService {
  ImageCacheService();

  /// 图片默认保留天数，超期自动删除
  static const int maxRetentionDays = 15;

  static const String dirName = 'question_cache';

  final Random _rng = Random();

  /// 缓存目录（应用文档目录下，持久保存）
  Future<Directory> dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, dirName));
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }

  /// 把 [srcPath] 复制进持久缓存，返回缓存内路径；
  /// 若该文件本就在缓存目录内则原样返回，避免无谓复制。
  Future<String> cacheImage(String srcPath) async {
    if (srcPath.isEmpty) return srcPath;
    final src = File(srcPath);
    if (!await src.exists()) return srcPath;
    final cacheDir = await dir();
    // 已在缓存目录内：直接复用
    if (src.absolute.path.startsWith(cacheDir.absolute.path)) return srcPath;
    final ext = p.extension(src.path).isEmpty ? '.jpg' : p.extension(src.path);
    final name = 'q_${DateTime.now().millisecondsSinceEpoch}_'
        '${_rng.nextInt(0xFFFFFF).toRadixString(16)}_$ext';
    await src.copy(p.join(cacheDir.path, name));
    return p.join(cacheDir.path, name);
  }

  /// 清理超过 [days] 天（按文件修改时间，默认 15 天）的缓存图片。
  /// @return 删除的文件数
  Future<int> cleanupExpired({int days = maxRetentionDays}) async {
    var removed = 0;
    try {
      final cacheDir = await dir();
      final now = DateTime.now();
      await for (final entity in cacheDir.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          if (age.inSeconds > days * 86400) {
            await entity.delete();
            removed++;
          }
        } catch (_) {
          // 单文件失败不影响其余
        }
      }
    } catch (_) {
      // 目录不可用时静默
    }
    return removed;
  }

  /// 清空全部缓存图片
  /// @return 删除的文件数
  Future<int> clearAll() async {
    var removed = 0;
    try {
      final cacheDir = await dir();
      await for (final entity in cacheDir.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          await entity.delete();
          removed++;
        } catch (_) {}
      }
    } catch (_) {}
    return removed;
  }

  /// 当前缓存统计（数量 + 占用字节）
  Future<ImageCacheStats> stats() async {
    var count = 0;
    var bytes = 0;
    try {
      final cacheDir = await dir();
      await for (final entity in cacheDir.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          count++;
          bytes += stat.size;
        } catch (_) {}
      }
    } catch (_) {}
    return ImageCacheStats(count: count, sizeBytes: bytes);
  }
}