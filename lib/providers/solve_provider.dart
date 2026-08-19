/// 解题状态管理 - 思谛 STDeel
///
/// Provider 模式：持有 AiService + FailoverManager + SyncService + 通知服务，
/// 暴露 [solve(imagePath)]、[retry(questionId)]、[askDetailed(questionId)]、
/// [markCorrect] / [markWrong] 等动作，并维护解题状态给 UI 监听。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../config/ai_config.dart';
import '../data/database.dart';
import '../models/solve_result.dart';
import '../services/ai_service.dart';
import '../services/backend_api.dart';
import '../services/failover_manager.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';


enum SolveStatus { idle, thinking, answering, done, error }

class SolveUiState {
  const SolveUiState({
    this.status = SolveStatus.idle,
    this.reasoningText = '',
    this.answerText = '',
    this.result,
    this.currentModel = '',
    this.notice,
    this.error,
  });

  final SolveStatus status;
  final String reasoningText;
  final String answerText;
  final SolveResult? result;
  final String currentModel;
  final String? notice;
  final String? error;

  SolveUiState copyWith({
    SolveStatus? status,
    String? reasoningText,
    String? answerText,
    SolveResult? result,
    String? currentModel,
    String? notice,
    String? error,
  }) =>
      SolveUiState(
        status: status ?? this.status,
        reasoningText: reasoningText ?? this.reasoningText,
        answerText: answerText ?? this.answerText,
        result: result ?? this.result,
        currentModel: currentModel ?? this.currentModel,
        notice: notice,
        error: error,
      );
}

class SolveProvider extends ChangeNotifier {
  SolveProvider({
    required FailoverManager failoverManager,
    required SyncService syncService,
    required NotificationService notificationService,
    required AppDatabase database,
    required BackendApi backendApi,
  })  : _failover = failoverManager,
        _sync = syncService,
        _notifier = notificationService,
        _db = database,
        _api = backendApi;

  final FailoverManager _failover;
  final SyncService _sync;
  final NotificationService _notifier;
  final AppDatabase _db;
  final BackendApi _api;

  SolveUiState _state = const SolveUiState();
  SolveUiState get state => _state;

  /// 拍照/选图后触发整轮 Failover 解题
  Future<void> solve({
    required String imagePath,
    required List<AiModelConfig> models,
    int thinkTimeout = 20,
  }) async {
    if (models.isEmpty) {
      _state = const SolveUiState(
        status: SolveStatus.error,
        error: '未配置可用的 AI 模型，请到「设置 → AI 模型组合」填写 API Key',
      );
      notifyListeners();
      return;
    }

    final sw = Stopwatch()..start();
    final file = File(imagePath);
    if (!await file.exists()) {
      _state = const SolveUiState(
        status: SolveStatus.error,
        error: '图片不存在',
      );
      notifyListeners();
      return;
    }
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    _state = const SolveUiState(
      status: SolveStatus.thinking,
      currentModel: '准备中',
    );
    notifyListeners();

    final sub = _failover
        .solve(
          models: models,
          base64Image: base64Image,
          thinkTimeoutSeconds: thinkTimeout,
        )
        .listen((event) => _handleStreamEvent(event, sw, imagePath));
    await sub.asFuture();
    await sub.cancel();
  }

  void _handleStreamEvent(AiStreamEvent event, Stopwatch sw, String? imagePath) {
    if (event is ThinkingStarted) {
      _state = _state.copyWith(
        status: SolveStatus.thinking,
        currentModel: event.modelName,
        notice: null,
      );
    } else if (event is ThinkingChunk) {
      _state = _state.copyWith(
        reasoningText: _state.reasoningText + event.text,
      );
    } else if (event is AnsweringStarted) {
      _state = _state.copyWith(
        status: SolveStatus.answering,
        currentModel: event.modelName,
        notice: null,
      );
    } else if (event is AnsweringChunk) {
      _state = _state.copyWith(
        answerText: _state.answerText + event.text,
      );
    } else if (event is ModelFailed) {
      _state = _state.copyWith(
        notice: '${event.modelName} 失败，切换至 ${event.nextModelName}…',
        currentModel: event.nextModelName,
      );
    } else if (event is AiDone) {
      sw.stop();
      final result = SolveResult(
        questions: event.result.questions,
        aiModel: event.result.aiModel,
        latencyMs: event.result.latencyMs,
        tokensUsed: event.result.tokensUsed,
        source: 'ai',
        imagePath: imagePath ?? '',
      );
      _state = SolveUiState(
        status: SolveStatus.done,
        result: result,
        currentModel: event.result.aiModel,
      );
      // 持久化到 drift，然后异步上传后端并标记已同步
      _persistResult(result).then((ids) {
        _sync.uploadSolveResult(result, recordIds: ids);
      });
      // 通知
      _notifier.notifySuccess(
        questionCount: result.questions.length,
        elapsed: Duration(milliseconds: result.latencyMs),
      );
    } else if (event is AiFailed) {
      _state = _state.copyWith(
        status: SolveStatus.error,
        error: event.reason,
      );
    }
    notifyListeners();
  }

  /// 写入 drift（每题一行），返回插入的记录 ID 列表
  Future<List<int>> _persistResult(SolveResult result) async {
    final ids = <int>[];
    for (final q in result.questions) {
      final id = await _db.solveRecordDao.insert(
        SolveRecordsCompanion.insert(
          questionText: q.content,
          answer: Value(q.answer),
          solution: Value(q.solution),
          knowledgePoints: Value(jsonEncode(q.knowledgePoints)),
          aiModel: Value(result.aiModel),
          latencyMs: Value(result.latencyMs),
          tokensUsed: Value(result.tokensUsed),
          matched: const Value(false),
          userFeedback: const Value('none'),
          imagePath: Value(result.imagePath),
        ),
      );
      ids.add(id);
    }
    return ids;
  }

  /// 标准答案库三层匹配：
  /// 1) 本地 drift hash 精确
  /// 2) 后端 FTS5
  /// 3) 不命中 → 走 AI（上层调用 [solve]）
  Future<QuestionResult?> tryMatchLibrary({
    required String questionText,
    required String questionHash,
  }) async {
    // 1. 本地精确
    final local = await _db.answerLibraryDao.matchByHash(questionHash);
    if (local != null) {
      return QuestionResult(
        id: local.id,
        content: local.questionText,
        knowledgePoints: _decodeKp(local.knowledgePoints),
        answer: local.answer,
        solution: local.solution,
      );
    }
    // 2. 后端匹配
    try {
      final resp = await _api.matchAnswer(
        questionText: questionText,
        questionHash: questionHash,
      );
      final sim = (resp['similarity'] as num?)?.toDouble() ?? 0.0;
      if (sim >= 0.85 && resp['hit'] == true) {
        final data = Map<String, dynamic>.from(resp['answer'] as Map);
        return QuestionResult(
          id: 0,
          content: questionText,
          knowledgePoints: _decodeKp((data['knowledge_points'] ?? '[]').toString()),
          answer: (data['answer'] ?? '').toString(),
          solution: (data['solution'] ?? '').toString(),
        );
      }
    } catch (_) {
      // 静默
    }
    return null;
  }

  List<String> _decodeKp(String raw) {
    try {
      final l = jsonDecode(raw);
      if (l is List) return l.map((e) => e.toString()).toList();
    } catch (_) {}
    return const [];
  }

  /// "正确"按钮
  Future<void> markCorrect({
    required int questionId,
    required List<String> knowledgePoints,
  }) async {
    await _db.solveRecordDao.updateFeedback(questionId, 'correct');
    for (final kp in knowledgePoints) {
      await _db.knowledgeDao.upsert(knowledgePoint: kp, deltaCorrect: 1);
    }
    await _sync.uploadFeedback(questionId, 'correct');
    notifyListeners();
  }

  /// "错误"按钮
  Future<void> markWrong({
    required int questionId,
    required List<String> knowledgePoints,
  }) async {
    await _db.solveRecordDao.updateFeedback(questionId, 'wrong');
    for (final kp in knowledgePoints) {
      await _db.knowledgeDao.upsert(knowledgePoint: kp, deltaWrong: 1);
    }
    await _sync.uploadFeedback(questionId, 'wrong');
    notifyListeners();
  }

  /// 纯文本调 AI（重答 / 疑问 / 举一反三共用）
  Future<void> _solveText({
    required String userPrompt,
    required int questionId,
    required List<AiModelConfig> models,
    required int thinkTimeout,
    required String startLabel,
    bool overwriteRecord = true,
  }) async {
    if (models.isEmpty) {
      _state = const SolveUiState(
        status: SolveStatus.error,
        error: '未配置可用的 AI 模型，请到「设置 → AI 模型组合」填写 API Key',
      );
      notifyListeners();
      return;
    }
    _state = SolveUiState(
      status: SolveStatus.thinking,
      currentModel: startLabel,
    );
    notifyListeners();
    final sub = _failover
        .solve(
          models: models,
          base64Image: null,
          userPrompt: userPrompt,
          thinkTimeoutSeconds: thinkTimeout,
        )
        .listen((event) {
      if (event is AiDone) {
        final q = event.result.questions.isNotEmpty
            ? event.result.questions.first
            : null;
        _state = SolveUiState(
          status: SolveStatus.done,
          result: event.result,
          currentModel: event.result.aiModel,
        );
        if (q != null && overwriteRecord && questionId > 0) {
          _db.solveRecordDao.overwriteAnswer(
            id: questionId,
            answer: q.answer,
            solution: q.solution,
            aiModel: event.result.aiModel,
            latencyMs: event.result.latencyMs,
            tokensUsed: event.result.tokensUsed,
            knowledgePoints: jsonEncode(q.knowledgePoints),
          );
        }
        notifyListeners();
        return;
      }
      _handleStreamEvent(event, Stopwatch(), null);
    });
    try {
      await sub.asFuture();
    } catch (_) {}
    await sub.cancel();
  }

  /// "重答"按钮：以高温度重调 AI 覆盖答案
  Future<void> retry({
    required int questionId,
    required String questionText,
    required List<AiModelConfig> models,
    int thinkTimeout = 20,
  }) =>
      _solveText(
        userPrompt: '请重新解答以下题目，给出新的答案与解答：\n$questionText',
        questionId: questionId,
        models: models,
        thinkTimeout: thinkTimeout,
        startLabel: '重答中',
      );

  /// "疑问"按钮：附加详细分步指令
  Future<void> askDetailed({
    required int questionId,
    required String questionText,
    required List<AiModelConfig> models,
    int thinkTimeout = 20,
  }) =>
      _solveText(
        userPrompt: '$questionText${AiConfig.detailedSolutionSuffix}',
        questionId: questionId,
        models: models,
        thinkTimeout: thinkTimeout,
        startLabel: '解答中',
      );

  /// 计算题目哈希（与本地答案库一致）
  String hashOf(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return sha256.convert(utf8.encode(normalized)).toString();
  }
}
