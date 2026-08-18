/// Failover 管理器 - 思谛 STDeel
///
/// 调用顺序：
///   1. 组合1 主模型 Qwen3.5 → 15s 未 think → 降级
///   2. 组合1 备用 Kimi K2.6 → 15s 未 think → 降级
///   3. 组合2 MathPix OCR → DeepSeek V4 两阶段
///
/// 每次降级发送通知 + 记录日志；全部失败发送失败通知。
library;

import 'dart:async';

import '../config/ai_config.dart';
import '../models/solve_result.dart';
import 'ai_service.dart';
import 'notification_service.dart';

class FailoverLogEntry {
  FailoverLogEntry(this.timestamp, this.message);

  final DateTime timestamp;
  final String message;

  @override
  String toString() =>
      '${timestamp.toIso8601String()} | $message';
}

class FailoverManager {
  FailoverManager({
    required AiService aiService,
    required NotificationService notificationService,
  })  : _ai = aiService,
        _notifier = notificationService;

  final AiService _ai;
  final NotificationService _notifier;
  final List<FailoverLogEntry> logs = [];

  void _log(String msg) {
    logs.add(FailoverLogEntry(DateTime.now(), msg));
  }

  /// 按组合顺序尝试，首个 think 成功的模型透传其事件流。
  /// 全部失败时发出 [AiFailed] 终止事件。
  ///
  /// [base64Image] 不为空时单阶段直发；组合2 会先 OCR 再用 LaTeX 求解。
  Stream<AiStreamEvent> solve({
    required AiComboConfig combo1,
    required AiComboConfig combo2,
    required String? base64Image,
    int thinkTimeoutSeconds = 15,
    String userPrompt = '',
  }) {
    final controller = StreamController<AiStreamEvent>();
    _run(controller, combo1, combo2, base64Image, thinkTimeoutSeconds,
        userPrompt);
    return controller.stream;
  }

  Future<void> _run(
    StreamController<AiStreamEvent> controller,
    AiComboConfig combo1,
    AiComboConfig combo2,
    String? base64Image,
    int thinkTimeoutSeconds,
    String userPrompt,
  ) async {
    final attempts = <AiModelConfig>[
      ...combo1.stages,
      ...combo2.stages,
    ];

    bool done = false;

    // === 组合1：Qwen3.5 → Kimi K2.6（单阶段多模态） ===
    for (final model in combo1.stages) {
      if (done) break;
      final ok = await _trySingleStage(
        controller: controller,
        model: model,
        base64Image: base64Image,
        userPrompt: userPrompt,
        thinkTimeoutSeconds: thinkTimeoutSeconds,
        onFailover: (next) {
          final msg = '${model.name} ${thinkTimeoutSeconds}s 内未开始思考，'
              '已自动切换至 ${next?.name ?? '下一组合'}';
          _log(msg);
          _notifier.notifyFailover(msg);
        },
      );
      if (ok) {
        done = true;
      }
    }

    // === 组合2：MathPix OCR → DeepSeek V4（两阶段） ===
    if (!done && base64Image != null && base64Image.isNotEmpty) {
      final ok = await _tryTwoStage(
        controller: controller,
        combo: combo2,
        base64Image: base64Image,
        thinkTimeoutSeconds: thinkTimeoutSeconds,
        userPrompt: userPrompt,
      );
      if (ok) {
        done = true;
      }
    }

    if (!done) {
      const msg = '解题失败：所有 AI 组合均未在限时内响应';
      _log(msg);
      _notifier.notifyFailure(msg);
      controller.add(const AiFailed(msg));
    }

    // silence unused-attempts lint
    if (attempts.isEmpty) return;
    await controller.close();
  }

  /// 单阶段尝试：监听子流，think 检测失败即取消并降级
  Future<bool> _trySingleStage({
    required StreamController<AiStreamEvent> controller,
    required AiModelConfig model,
    required String? base64Image,
    required String userPrompt,
    required int thinkTimeoutSeconds,
    required void Function(AiModelConfig? next) onFailover,
  }) async {
    final subCompleter = Completer<bool>();
    bool thinkingStarted = false;
    StreamSubscription? sub;

    sub = _ai.callModelStream(
      model: model,
      base64Image: base64Image,
      userPrompt: userPrompt,
      thinkTimeoutSeconds: thinkTimeoutSeconds,
    ).listen(
      (event) {
        if (event is ThinkingStarted || event is ThinkingChunk) {
          thinkingStarted = true;
        }
        if (event is AiFailed) {
          if (!subCompleter.isCompleted) {
            subCompleter.complete(false);
          }
          return;
        }
        if (event is AiDone) {
          controller.add(event);
          if (!subCompleter.isCompleted) subCompleter.complete(true);
        } else {
          controller.add(event);
        }
      },
      onError: (e) {
        if (!subCompleter.isCompleted) subCompleter.complete(false);
      },
      onDone: () {
        if (!subCompleter.isCompleted) {
          subCompleter.complete(thinkingStarted);
        }
      },
    );

    final success = await subCompleter.future;
    await sub.cancel();
    // 如果未 think 起步，触发降级通知
    if (!success && !thinkingStarted) {
      onFailover(null);
    }
    return success;
  }

  /// 两阶段：OCR → 用 LaTeX 调 DeepSeek 求解
  Future<bool> _tryTwoStage({
    required StreamController<AiStreamEvent> controller,
    required AiComboConfig combo,
    required String base64Image,
    required int thinkTimeoutSeconds,
    required String userPrompt,
  }) async {
    if (combo.stages.length < 2) return false;
    final ocr = combo.stages.first;
    final solver = combo.stages[1];

    // 阶段1：OCR
    String latex;
    try {
      latex = await _ai.runOcrStage(
        model: ocr,
        base64Image: base64Image,
      );
    } catch (e) {
      final msg = '${ocr.name} OCR 失败：$e';
      _log(msg);
      _notifier.notifyFailover(msg);
      return false;
    }
    if (latex.trim().isEmpty) {
      _log('${ocr.name} OCR 返回空');
      return false;
    }

    // 阶段2：DeepSeek 求解
    final subCompleter = Completer<bool>();
    StreamSubscription? sub;
    sub = _ai.callSolutionStage(
      model: solver,
      latexText: latex,
      thinkTimeoutSeconds: thinkTimeoutSeconds,
    ).listen(
      (event) {
        if (event is AiFailed) {
          if (!subCompleter.isCompleted) subCompleter.complete(false);
          return;
        }
        if (event is AiDone) {
          controller.add(event);
          if (!subCompleter.isCompleted) subCompleter.complete(true);
        } else {
          controller.add(event);
        }
      },
      onError: (e) {
        if (!subCompleter.isCompleted) subCompleter.complete(false);
      },
      onDone: () {
        if (!subCompleter.isCompleted) subCompleter.complete(false);
      },
    );
    final success = await subCompleter.future;
    await sub.cancel();
    if (!success) {
      final msg = '${solver.name} 求解阶段失败';
      _log(msg);
    }
    return success;
  }
}
