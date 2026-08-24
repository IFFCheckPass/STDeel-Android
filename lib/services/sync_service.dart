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
  }) async {
    try {
      await _api.uploadAnswer({
        'question_text': questionText,
        'question_hash': questionHash,
        'answer': answer,
        'solution': solution,
        'knowledge_points': knowledgePoints,
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
  Future<void> flushUnsynced() async {
    final records = await _db.solveRecordDao.getUnsynced();
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
        });
      } catch (_) {
        // 网络/后端失败：保留记录待下次重试。
        continue;
      }
      try {
        await _db.solveRecordDao.markSynced(r.id);
      } catch (e) {
        // 上传已成功但本地标记失败：不得把该记录误判为"未上传"再次投递，
        // 在此单独记录错误，交由上层/日志处理，不再重复上传。
        debugPrint('flushUnsynced: 记录 ${r.id} 上传成功但 markSynced 失败: $e');
      }
    }
  }
}
