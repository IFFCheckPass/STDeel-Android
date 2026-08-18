/// AI 调用服务 - 思谛 STDeel
///
/// 前端直连 AI API（OpenAI 兼容），通过 Dio 发起流式请求，
/// 手动解析 SSE 流并检测 `reasoning_content` 字段（think 检测）。
///
/// 关键逻辑：
///   1. POST /chat/completions，body 中 `stream: true`
///   2. 逐行读取 `data:` 前缀的 SSE 帧
///   3. 检测 `choices[0].delta.reasoning_content`
///   4. 在 thinkTimeout 内未收到非空 reasoning_content → 抛 TimeoutException（触发 Failover）
///   5. 收到 reasoning_content 阶段 → UI 显示"AI 思考中..."
///      收到 content 阶段 → UI 显示"AI 回答中..."
///   6. [DONE] 后解析完整 JSON 得到 [QuestionResult]
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/ai_config.dart';
import '../models/solve_result.dart';

/// 流式事件，供 UI 与 FailoverManager 消费
sealed class AiStreamEvent {
  const AiStreamEvent();
}

class ThinkingStarted extends AiStreamEvent {
  const ThinkingStarted(this.modelName);
  final String modelName;
}

class ThinkingChunk extends AiStreamEvent {
  const ThinkingChunk(this.text);
  final String text;
}

class AnsweringStarted extends AiStreamEvent {
  const AnsweringStarted(this.modelName);
  final String modelName;
}

class AnsweringChunk extends AiStreamEvent {
  const AnsweringChunk(this.text);
  final String text;
}

class AiDone extends AiStreamEvent {
  const AiDone(this.result);
  final SolveResult result;
}

class AiFailed extends AiStreamEvent {
  const AiFailed(this.reason);
  final String reason;
}

/// 单次 AI 调用结果（不含 Failover）
class AiCallOutcome {
  const AiCallOutcome({
    required this.questions,
    required this.model,
    required this.latencyMs,
    required this.tokensUsed,
    required this.success,
    this.error,
  });

  final List<QuestionResult> questions;
  final String model;
  final int latencyMs;
  final int tokensUsed;
  final bool success;
  final String? error;
}

class ThinkTimeoutException implements Exception {
  const ThinkTimeoutException(this.model, this.seconds);
  final String model;
  final int seconds;

  @override
  String toString() => '$model 在 ${seconds}s 内未检测到思维链';
}

class AiService {
  AiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// 对单个模型发起流式调用，返回事件流。
  ///
  /// [thinkTimeoutSeconds] 内未收到非空 reasoning_content →
  /// 流以 [AiFailed]（ThinkTimeoutException reason）结束，触发上层 Failover。
  ///
  /// [userPrompt] 可附加额外指令（重答/疑问场景）。
  /// [base64Image] 不为空时以多模态格式发送。
  Stream<AiStreamEvent> callModelStream({
    required AiModelConfig model,
    required String? base64Image,
    String userPrompt = '',
    int thinkTimeoutSeconds = 15,
    double temperature = 0.6,
  }) {
    final controller = StreamController<AiStreamEvent>();
    final stopWatch = Stopwatch()..start();

    _runStream(
      controller: controller,
      model: model,
      base64Image: base64Image,
      userPrompt: userPrompt,
      thinkTimeoutSeconds: thinkTimeoutSeconds,
      temperature: temperature,
      stopWatch: stopWatch,
    ).whenComplete(() {
      if (!controller.isClosed) controller.close();
    });

    return controller.stream;
  }

  Future<void> _runStream({
    required StreamController<AiStreamEvent> controller,
    required AiModelConfig model,
    required String? base64Image,
    required String userPrompt,
    required int thinkTimeoutSeconds,
    required double temperature,
    required Stopwatch stopWatch,
  }) async {
    final url = '${model.endpoint}/chat/completions';
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': AiConfig.systemPrompt},
    ];

    if (base64Image != null && base64Image.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userPrompt.isEmpty ? '请解题' : userPrompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
        ],
      });
    } else {
      messages.add({
        'role': 'user',
        'content': userPrompt.isEmpty ? '请解题' : userPrompt,
      });
    }

    final body = <String, dynamic>{
      'model': model.model,
      'messages': messages,
      'stream': true,
      'temperature': temperature,
    };
    // Kimi 需显式开启 thinking
    if (model.enableThinking) {
      body['thinking'] = {'type': 'enabled'};
    }

    // 用 CancelToken 让 think 超时能真正取消 HTTP 请求
    final cancelToken = CancelToken();
    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        url,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${model.apiKey}',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
          // 整体请求超时设宽松一点，think 检测由内部计时器控制
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
    } on DioException catch (e) {
      controller.add(AiFailed('请求失败: ${e.message ?? e.type.name}'));
      return;
    }

    if (response.data == null) {
      controller.add(const AiFailed('响应体为空'));
      return;
    }

    final stream = response.data!.stream.transform(
      Utf8Decoder(allowMalformed: true),
    );
    final buffer = StringBuffer();
    bool thinkingDetected = false;
    bool answeringStarted = false;
    String reasoningContent = '';
    String answerContent = '';
    int tokensUsed = 0;

    // think 检测计时器：到点未 think → 取消请求 + 发 AiFailed（触发 Failover）
    Timer? thinkTimer;
    final completer = Completer<void>();

    thinkTimer = Timer(Duration(seconds: thinkTimeoutSeconds), () {
      if (!thinkingDetected && !completer.isCompleted) {
        // 真正取消底层 HTTP 流，让 await for 自然结束
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('think 超时：未在 ${thinkTimeoutSeconds}s 内检测到思维链');
        }
        controller.add(
          AiFailed('未在 ${thinkTimeoutSeconds}s 内检测到思维链'),
        );
        completer.complete();
      }
    });

    try {
      await for (final chunk in stream) {
        if (completer.isCompleted) break;

        buffer.write(chunk);

        // 按行拆分，最后一行可能不完整，需保留在 buffer
        final raw = buffer.toString();
        final lines = raw.split('\n');
        // 留最后一行到 buffer
        buffer.clear();
        buffer.write(lines.removeLast());

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (!trimmed.startsWith('data:')) continue;

          // 'data: ' 或 'data:'
          var data = trimmed.substring(5);
          if (data.startsWith(' ')) data = data.substring(1);

          if (data.trim() == '[DONE]') {
            tokensUsed = _estimateTokens(reasoningContent, answerContent);
            final questions = _parseAnswerJson(answerContent);
            controller.add(
              AiDone(SolveResult(
                questions: questions,
                aiModel: model.name,
                latencyMs: stopWatch.elapsedMilliseconds,
                tokensUsed: tokensUsed,
                source: 'ai',
              )),
            );
            if (!completer.isCompleted) completer.complete();
            return;
          }

          Map<String, dynamic> json;
          try {
            json = jsonDecode(data) as Map<String, dynamic>;
          } catch (_) {
            continue;
          }

          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;
          final delta =
              (choices[0] as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;

          if (delta == null) continue;

          final reasoning =
              delta['reasoning_content'] as String?;
          final content = delta['content'] as String?;

          if (reasoning != null && reasoning.isNotEmpty) {
            if (!thinkingDetected) {
              thinkingDetected = true;
              thinkTimer?.cancel();
              controller.add(ThinkingStarted(model.name));
            }
            reasoningContent += reasoning;
            controller.add(ThinkingChunk(reasoning));
          }

          if (content != null && content.isNotEmpty) {
            if (!answeringStarted) {
              answeringStarted = true;
              controller.add(AnsweringStarted(model.name));
            }
            answerContent += content;
            controller.add(AnsweringChunk(content));
          }
        }
      }
    } on TimeoutException {
      // 下层 timeout，通常不会到这里（ Dio 接收超时会抛 DioException）
      if (!completer.isCompleted) {
        controller.add(const AiFailed('流读取超时'));
        completer.complete();
      }
    } catch (e) {
      // 取消触发的 DioException 会到这里，但 completer 已被 timer 完成
      if (!completer.isCompleted) {
        controller.add(AiFailed('流解析异常: $e'));
        completer.complete();
      }
    } finally {
      thinkTimer?.cancel();
      // 若未发送 Done 也未 Failed，至少补一个 Failed
      if (!completer.isCompleted) {
        if (answerContent.isNotEmpty) {
          final questions = _parseAnswerJson(answerContent);
          controller.add(
            AiDone(SolveResult(
              questions: questions,
              aiModel: model.name,
              latencyMs: stopWatch.elapsedMilliseconds,
              tokensUsed: _estimateTokens(reasoningContent, answerContent),
              source: 'ai',
            )),
          );
        } else {
          controller.add(const AiFailed('流提前结束且无内容'));
        }
        completer.complete();
      }
    }
  }

  /// 解析 AI 返回的完整 JSON 字符串 → [QuestionResult]
  ///
  /// 容忍 model 返回 markdown ```json 围栏
  List<QuestionResult> _parseAnswer(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'^```(?:json)?'), '').replaceAll(RegExp(r'```$'), '').trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end < 0 || end <= start) return [];
    final slice = text.substring(start, end + 1);
    try {
      final decoded = jsonDecode(slice) as Map<String, dynamic>;
      final list = decoded['questions'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              QuestionResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<QuestionResult> _parseAnswerJson(String raw) => _parseAnswer(raw);

  int _estimateTokens(String reasoning, String content) =>
      ((reasoning.length + content.length) / 4).ceil();

  /// 第二阶段：用纯文本（LaTeX）调用 DeepSeek 求解
  Stream<AiStreamEvent> callSolutionStage({
    required AiModelConfig model,
    required String latexText,
    int thinkTimeoutSeconds = 15,
  }) =>
      callModelStream(
        model: model,
        base64Image: null,
        userPrompt: AiConfig.solutionPrompt(latexText),
        thinkTimeoutSeconds: thinkTimeoutSeconds,
      );

  /// 第一阶段：MathPix OCR —— 简化为直接调用同端点，提取 LaTeX 文本
  Future<String> runOcrStage({
    required AiModelConfig model,
    required String base64Image,
  }) async {
    final completer = Completer<String>();
    String collected = '';
    late StreamSubscription sub;
    sub = callModelStream(
      model: model,
      base64Image: base64Image,
      userPrompt: '请将图片中的题目转换为 LaTeX 文本，仅返回 LaTeX。',
      thinkTimeoutSeconds: 15,
    ).listen(
      (event) {
        if (event is AnsweringChunk) {
          collected += event.text;
        } else if (event is AiDone) {
          completer.complete(collected.isNotEmpty
              ? collected
              : event.result.questions
                  .map((q) => q.content)
                  .join('\n'));
        } else if (event is AiFailed) {
          completer.completeError(event.reason);
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(collected);
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future.whenComplete(sub.cancel);
  }
}
