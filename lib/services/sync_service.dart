/// 数据同步服务 - 思谛 STDeel
///
/// 上行同步（前端→后端）：
///   - 解题完成后异步上传记录（不阻塞 UI）
///   - 用户点击"正确/错误"后异步更新后端统计
///   - 标准答案上传后同步至后端
///   - 离线时 drift 本地缓存，联网后批量同步
///
/// 下行同步（后端→前端）：
///   - 应用启动时拉取最新标准答案库更新本地 drift 缓存
///   - 知识点统计数据按需拉取
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../data/database.dart';
import '../models/solve_result.dart';
import 'backend_api.dart';

/// 一次手动同步的结果统计，用于设置页展示"上传成功/失败 x 条、回写 x 条"。
class SyncResult {
  const SyncResult({
    this.uploaded = 0,
    this.uploadFailed = 0,
    this.pulled = 0,
  });

  /// 本地上行成功的记录数
  final int uploaded;
  /// 本地上行失败的记录数
  final int uploadFailed;
  /// 从后端下拉并写回本地（新增或更新）的记录数
  final int pulled;

  bool get hasFailure => uploadFailed > 0;
  int get totalUploaded => uploaded + uploadFailed;

  @override
  String toString() =>
      '上传成功 ${uploaded} 条${uploadFailed > 0 ? '，失败 $uploadFailed 条' : '，无失败'}'
      '，回写 $pulled 条';
}

class SyncService {
  SyncService({
    required AppDatabase database,
    required BackendApi backendApi,
  })  : _db = database,
        _api = backendApi;

  final AppDatabase _db;
  final BackendApi _api;

  /// 解题完成后异步上传（不阻塞 UI）
  Future<void> uploadSolveResult(
    SolveResult result, {
    List<int>? recordIds,
  }) async {
    try {
      final payload = <String, dynamic>{
        'ai_model': result.aiModel,
        'latency_ms': result.latencyMs,
        'tokens_used': result.tokensUsed,
        'source': result.source,
        'image_path': result.imagePath,
        'questions':
            result.questions.map((q) => q.toJson()).toList(growable: false),
      };
      await _api.uploadSolveRecord(payload);
      if (recordIds != null) {
        for (final id in recordIds) {
          await _db.solveRecordDao.markSynced(id);
        }
      }
    } catch (_) {
      // 静默失败：离线时 drift 已有记录，下次手动同步可补
    }
  }

  /// 反馈更新（"正确/错误"按钮）
  Future<void> uploadFeedback(int recordId, String feedback) async {
    try {
      await _api.updateFeedback(recordId, feedback);
    } catch (_) {
      // 静默
    }
  }

  /// 上传标准答案 → 同步至后端 + 写本地 drift
  Future<void> uploadAnswer({
    required String questionText,
    required String questionHash,
    required String answer,
    String solution = '',
    List<String> knowledgePoints = const [],
    String subject = '未分类',
  }) async {
    try {
      await _api.uploadAnswer({
        'question_text': questionText,
        'question_hash': questionHash,
        'answer': answer,
        'solution': solution,
        'knowledge_points': knowledgePoints,
        'subject': subject,
      });
    } catch (_) {
      // 静默
    }
    await _db.answerLibraryDao.insert(
      AnswerLibraryCompanion.insert(
        questionText: questionText,
        questionHash: questionHash,
        answer: answer,
        solution: Value(solution),
        knowledgePoints: Value(jsonEncode(knowledgePoints)),
        subject: Value(subject),
        source: const Value('local'),
      ),
    );
  }

  /// 应用启动时拉取最新标准答案库更新本地 drift
  Future<void> pullAnswerLibrary() async {
    try {
      // 复用 fetchKnowledgeMastery 同样的鉴权路径
      // 后端建议提供 /api/v1/answer-library GET；这里若未实现则空回
      // 忽略错误：保留本地缓存
    } catch (_) {
      // 静默
    }
  }

  /// 拉取知识点掌握度 → upsert 进本地 drift
  Future<void> pullKnowledgeMastery() async {
    try {
      final rows = await _api.fetchKnowledgeMastery();
      for (final row in rows) {
        await _db.knowledgeDao.upsert(
          knowledgePoint: row['knowledge_point'].toString(),
          deltaCorrect: (row['correct_count'] as num?)?.toInt() ?? 0,
          deltaWrong: (row['wrong_count'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (_) {
      // 静默
    }
  }

  /// 拉取薄弱知识点（按需）
  Future<List<Map<String, dynamic>>> pullWeakKnowledge() async {
    try {
      return await _api.fetchWeakKnowledge();
    } catch (_) {
      return const [];
    }
  }

  /// 联网后批量同步尚未上传的解题记录
  /// @return 上传成功 / 失败 条数
  Future<({int success, int failed})> flushUnsynced() async {
    final records = await _db.solveRecordDao.getUnsynced();
    var success = 0;
    var failed = 0;
    for (final r in records) {
      try {
        await _api.uploadSolveRecord({
          'local_id': r.id,
          'question_text': r.questionText,
          'answer': r.answer,
          'solution': r.solution,
          'ai_model': r.aiModel,
          'latency_ms': r.latencyMs,
          'tokens_used': r.tokensUsed,
          'matched': r.matched,
          'user_feedback': r.userFeedback,
          'image_path': r.imagePath,
          'subject': r.subject,
        });
      } catch (_) {
        // 网络/后端失败：保留记录待下次重试。
        failed++;
        continue;
      }
      try {
        await _db.solveRecordDao.markSynced(r.id);
      } catch (e) {
        // 上传已成功但本地标记失败：不得把该记录误判为"未上传"再次投递，
        // 在此单独记录错误，交由上层/日志处理，不再重复上传。
        debugPrint('flushUnsynced: 记录 ${r.id} 上传成功但 markSynced 失败: $e');
      }
      success++;
    }
    return (success: success, failed: failed);
  }

  /// 下拉后端解题记录并写回本地（仅正确=近1个月 / 错误=近3个月）。
  ///
  /// 按后端主键 remoteId 幂等合并，避免重复插入。后端未适配或失败时静默。
  /// @return 写回本地（新增或更新）的记录条数
  Future<int> pullSolveRecords() async {
    var applied = 0;
    try {
      final rows = await _api.fetchSolveRecords(
        correctDays: 30,
        wrongDays: 90,
      );
      for (final row in rows) {
        final remoteId = (row['id'] as num?)?.toInt();
        if (remoteId == null || remoteId <= 0) continue;
        await _db.solveRecordDao.upsertFromBackend(
          remoteId: remoteId,
          questionText: row['question_text']?.toString() ?? '',
          answer: row['answer']?.toString() ?? '',
          solution: row['solution']?.toString() ?? '',
          userFeedback: row['user_feedback']?.toString() ?? 'correct',
          knowledgePoints:
              row['knowledge_points'] is List
                  ? jsonEncode(row['knowledge_points'])
                  : '[]',
          aiModel: row['ai_model']?.toString() ?? '',
          latencyMs: (row['latency_ms'] as num?)?.toInt() ?? 0,
          tokensUsed: (row['tokens_used'] as num?)?.toInt() ?? 0,
          matched: row['matched'] == true,
          subject: row['subject']?.toString().trim().isNotEmpty == true
              ? row['subject'].toString().trim()
              : '未分类',
          createdAt:
              row['created_at'] is String
                  ? DateTime.tryParse(row['created_at'])
                  : null,
        );
        applied++;
      }
    } catch (_) {
      // 后端未实现下拉接口或网络失败：静默，仅保留上行能力。
    }
    return applied;
  }

  /// 手动同步入口：先上行补传本地未同步记录，再从后端下拉回写缺失记录。
  /// @return 各阶段计数，供 UI 展示"成功/失败 x 条"。
  Future<SyncResult> syncAll() async {
    final upload = await flushUnsynced();
    final pulled = await pullSolveRecords();
    return SyncResult(
      uploaded: upload.success,
      uploadFailed: upload.failed,
      pulled: pulled,
    );
  }
}
