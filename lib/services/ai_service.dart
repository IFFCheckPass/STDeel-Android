/// AI 调用服务 - 思谛 STDeel
///
/// 前端直连 AI API（OpenAI 兼容），通过 Dio 发起流式请求，
/// 手动解析 SSE 流并检测 `reasoning_content` 字段（think 检测）。
///
/// 关键逻辑：
///   1. POST /chat/completions，body 中 `stream: true`
///   2. 逐行读取 `data:` 前缀的 SSE 帧
///   3. think 超时计时从【发起请求】开始：
///      - 在 thinkTimeout 内收到首个 reasoning_content 或 content 块 → 取消计时
///      - 到点仍无任何内容 → 取消请求并抛 AiFailed（触发 Failover）
///   4. [DONE] 后解析完整 JSON 得到 [QuestionResult]
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/ai_config.dart';
import '../models/solve_result.dart';
import 'fault_log_service.dart';

/// 流式事件，供 UI 与 FailoverManager 消费
abstract class AiStreamEvent {
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

class ThinkTimeoutException implements Exception {
  const ThinkTimeoutException(this.model, this.seconds);
  final String model;
  final int seconds;

  @override
  String toString() => '$model 在 ${seconds}s 内未输出任何内容';
}

class AiService {
  AiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  void _safeAdd(StreamController<AiStreamEvent> c, AiStreamEvent e) {
    if (!c.isClosed) c.add(e);
  }

  /// 对单个模型发起流式调用，返回事件流。
  Stream<AiStreamEvent> callModelStream({
    required AiModelConfig model,
    required String? base64Image,
    String userPrompt = '',
    int thinkTimeoutSeconds = 20,
  }) {
    final controller = StreamController<AiStreamEvent>();
    final stopWatch = Stopwatch()..start();

    _runStream(
      controller: controller,
      model: model,
      base64Image: base64Image,
      userPrompt: userPrompt,
      thinkTimeoutSeconds: thinkTimeoutSeconds,
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
    };

    // 用 CancelToken 让 think 超时能真正取消 HTTP 请求
    final cancelToken = CancelToken();
    final completer = Completer<void>();

    /// 只发送一次失败事件
    void fail(String reason) {
      if (!completer.isCompleted) {
        completer.complete();
        _safeAdd(controller, AiFailed(reason));
      }
    }

    // think 计时从发起请求开始（含连接 + 模型排队时间），
    // 收到首个 reasoning 或 content 块即视为"模型已开始响应"。
    final thinkTimer = Timer(Duration(seconds: thinkTimeoutSeconds), () {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('think 超时');
      }
      fail('${model.name}（${model.model}）在 ${thinkTimeoutSeconds}s 内'
          '未输出任何内容，已自动切换下一模型');
    });

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
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
    } on DioException catch (e) {
      thinkTimer.cancel();
      if (completer.isCompleted) return; // think 超时已处理
      fail('请求失败（${model.name}）: ${await _dioErrorText(e)}');
      return;
    } catch (e) {
      thinkTimer.cancel();
      if (completer.isCompleted) return;
      fail('请求失败（${model.name}）: $e');
      return;
    }

    if (response.data == null) {
      thinkTimer.cancel();
      fail('响应体为空（${model.name}）');
      return;
    }

    final stream = response.data!.stream.cast<List<int>>().transform(
      utf8.decoder,
    );
    final buffer = StringBuffer();
    bool thinkingStarted = false;
    bool answeringStarted = false;
    String reasoningContent = '';
    String answerContent = '';

    try {
      await for (final chunk in stream) {
        if (completer.isCompleted) break;

        buffer.write(chunk);

        // 按行拆分，最后一行可能不完整，需保留在 buffer
        final raw = buffer.toString();
        final lines = raw.split('\n');
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
            thinkTimer.cancel();
            final questions = _parseAnswer(answerContent);
            _safeAdd(
              controller,
              AiDone(SolveResult(
                questions: questions,
                aiModel: model.name,
                latencyMs: stopWatch.elapsedMilliseconds,
                tokensUsed: _estimateTokens(reasoningContent, answerContent),
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

          final reasoning = delta['reasoning_content'] as String?;
          final content = delta['content'] as String?;
          final hasReasoning = reasoning != null && reasoning.isNotEmpty;
          final hasContent = content != null && content.isNotEmpty;

          // 只要模型开始输出（无论思考还是回答），think 计时即结束
          if (hasReasoning || hasContent) {
            thinkTimer.cancel();
          }

          if (hasReasoning) {
            if (!thinkingStarted) {
              thinkingStarted = true;
              _safeAdd(controller, ThinkingStarted(model.name));
            }
            reasoningContent += reasoning;
            _safeAdd(controller, ThinkingChunk(reasoning));
          }

          if (hasContent) {
            if (!answeringStarted) {
              answeringStarted = true;
              _safeAdd(controller, AnsweringStarted(model.name));
            }
            answerContent += content;
            _safeAdd(controller, AnsweringChunk(content));
          }
        }
      }
    } catch (e) {
      // 取消触发的异常：completer 已由计时器完成，忽略
      if (!completer.isCompleted) {
        fail('流解析异常（${model.name}）: $e');
      }
    } finally {
      thinkTimer.cancel();
      // 流自然结束但未收到 [DONE]：有内容则视为完成
      if (!completer.isCompleted) {
        if (answerContent.isNotEmpty) {
          final questions = _parseAnswer(answerContent);
          _safeAdd(
            controller,
            AiDone(SolveResult(
              questions: questions,
              aiModel: model.name,
              latencyMs: stopWatch.elapsedMilliseconds,
              tokensUsed: _estimateTokens(reasoningContent, answerContent),
              source: 'ai',
            )),
          );
        } else {
          fail('${model.name} 连接已断开且未返回内容');
        }
        completer.complete();
      }
    }
  }

  /// 从 DioException 中提取可读的错误信息（含 HTTP 状态码与响应体）。
  /// 始终返回中文文案；同时记录一条故障码到 [FaultLogService]，便于在设置页查看/复制。
  Future<String> _dioErrorText(DioException e, {String source = 'AI 调用'}) async {
    final resp = e.response;
    if (resp != null) {
      var msg = 'HTTP ${resp.statusCode}';
      final data = resp.data;
      if (data is ResponseBody) {
        try {
          final chunks = await data.stream.toList();
          final text = utf8.decode(
            chunks.expand((c) => c).toList(growable: false),
          );
          final err = _extractApiError(text);
          if (err != null && err.isNotEmpty) msg = 'HTTP ${resp.statusCode} $err';
        } catch (_) {/* 忽略读取失败 */}
      } else if (data is Map && data['error'] is Map) {
        final m = (data['error'] as Map)['message'];
        if (m != null) msg = 'HTTP ${resp.statusCode} $m';
      }
      // 记录故障码，供设置页展示/复制；文案统一为中文。
      final cn = _zhHttpMessage(resp.statusCode);
      FaultLogService.instance.record(
        source: source,
        code: '${resp.statusCode}',
        summary: _trimCn(cn + (resp.statusCode == 404 &&
                (msg.contains('api.github.com') || msg.contains('github'))
            ? '（GitHub 资源/版本不存在或已被限制访问）'
            : '')),
      );
      if (resp.statusCode == 404 || resp.statusCode == 403 || resp.statusCode == 429) {
        return 'HTTP ${resp.statusCode} $cn';
      }
      return msg;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        FaultLogService.instance.record(source: source, code: '超时', summary: '网络连接超时');
        return '连接超时';
      case DioExceptionType.connectionError:
        FaultLogService.instance.record(source: source, code: '网络', summary: '无法连接服务器');
        return '无法连接服务器（请检查网络或 Base URL）';
      case DioExceptionType.badCertificate:
        FaultLogService.instance.record(source: source, code: '证书', summary: '证书校验失败');
        return '证书校验失败';
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        FaultLogService.instance.record(source: source, code: '未知', summary: '${e.message ?? e.type.name}');
        return '网络请求异常（${e.message ?? e.type.name}）';
    }
  }

  /// HTTP 状态码 → 中文说明（故障展示统一中文）
  String _zhHttpMessage(int? code) {
    switch (code) {
      case 400:
        return '请求参数有误';
      case 401:
        return '认证失败（API Key 无效或权限不足）';
      case 403:
        return '访问被拒绝（禁止访问，可能是限流或权限不足）';
      case 404:
        return '请求的资源不存在';
      case 405:
        return '请求方法不允许';
      case 408:
        return '请求超时';
      case 409:
        return '资源冲突';
      case 422:
        return '请求内容校验失败';
      case 429:
        return '请求过于频繁，已触发限流，请稍后再试';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务暂不可用';
      case 504:
        return '网关超时';
      default:
        return code == null ? '未知错误' : 'HTTP 错误（$code）';
    }
  }

  String _trimCn(String s) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  /// 尝试从响应体文本中提取 error.message
  String? _extractApiError(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {
      if (text.length <= 160) return text;
    }
    return null;
  }

  /// 解析 AI 返回的内容 → [QuestionResult]
  ///
  /// 优先解析 `{questions: [...]}` 结构；同时兼容模型直接返回单题对象
  /// 或纯数组的情况，尽量降低"解析失败→空结果→误切换"的概率。
  /// 容忍 markdown ```json 围栏。
  List<QuestionResult> _parseAnswer(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text
          .replaceAll(RegExp(r'^```(?:json)?'), '')
          .replaceAll(RegExp(r'```$'), '')
          .trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');

    // 顶层可能直接是数组 [ {...}, {...} ]
    if ((start < 0 || end < 0) && text.startsWith('[')) {
      final a = text.indexOf('[');
      final z = text.lastIndexOf(']');
      if (a >= 0 && z > a) {
        final slice = text.substring(a, z + 1);
        try {
          final list = jsonDecode(slice) as List<dynamic>;
          return list
              .map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          return [];
        }
      }
    }
    if (start < 0 || end < 0 || end <= start) return [];
    final slice = text.substring(start, end + 1);
    try {
      final decoded = jsonDecode(slice) as Map<String, dynamic>;
      final list = decoded['questions'] as List<dynamic>?;
      if (list != null) {
        return list
            .map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // 直接返回单题对象 { content, answer, ... }
      if (decoded['content'] != null || decoded['answer'] != null) {
        return [QuestionResult.fromJson(Map<String, dynamic>.from(decoded))];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  int _estimateTokens(String reasoning, String content) =>
      ((reasoning.length + content.length) / 4).ceil();

  /// 一次性（非流式）生成：把一段文本/若干图片发给单个模型，返回完整文本。
  ///
  /// 用于答案库文档拆分等场景：优先由多模态模型读图/文并输出结构化 JSON。
  /// 失败时抛字符串异常（可读原因）。
  Future<String> generateRaw({
    required AiModelConfig model,
    required String userText,
    List<String> imageDataUrls = const [],
    double temperature = 0.2,
    int timeoutSeconds = 180,
  }) async {
    final url = '${model.endpoint}/chat/completions';
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': AiConfig.documentSplitPrompt},
    ];
    if (imageDataUrls.isEmpty) {
      messages.add({'role': 'user', 'content': userText});
    } else {
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userText},
          for (final du in imageDataUrls)
            {
              'type': 'image_url',
              'image_url': {'url': du},
            },
        ],
      });
    }
    final body = <String, dynamic>{
      'model': model.model,
      'messages': messages,
      'stream': false,
      'temperature': temperature,
    };
    try {
      final resp = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${model.apiKey}',
            'Content-Type': 'application/json',
          },
          receiveTimeout: Duration(seconds: timeoutSeconds),
        ),
      );
      final data = resp.data;
      String? content;
      if (data is Map) {
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final m = (choices[0] as Map)['message'] as Map?;
          final c = m?['content'];
          if (c is String) content = c;
        }
      }
      final text = content?.trim() ?? '';
      if (text.isEmpty) throw '模型未返回内容';
      return text;
    } on DioException catch (e) {
      throw await _dioErrorText(e);
    }
  }

  /// 获取模型列表：GET {baseUrl}/models
  ///
  /// 返回按字母排序的模型 ID 列表；失败抛异常（含原因）。
  Future<List<String>> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    final url = '$baseUrl/models';
    try {
      final resp = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final data = resp.data;
      List<dynamic>? rawList;
      if (data is Map) {
        rawList = data['data'] as List<dynamic>?;
      }
      if (rawList == null) {
        throw '响应格式异常：未找到 data 数组';
      }
      final ids = rawList
          .map((e) {
            if (e is Map && e['id'] != null) return e['id'].toString();
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      ids.sort();
      return ids;
    } on DioException catch (e) {
      throw await _dioErrorText(e);
    }
  }

  /// 连通性测试：向 {baseUrl}/chat/completions 发送一条极小请求。
  ///
  /// 返回 (成功与否, 耗时ms, 详细信息)。
  Future<({bool ok, int latencyMs, String message})> testConnection({
    required String baseUrl,
    required String apiKey,
    required String modelId,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final resp = await _dio.post<dynamic>(
        '$baseUrl/chat/completions',
        data: {
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': 'ping'},
          ],
          'max_tokens': 4,
          'stream': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      sw.stop();
      if (resp.statusCode == 200) {
        return (
          ok: true,
          latencyMs: sw.elapsedMilliseconds,
          message: '连接成功，延迟 ${sw.elapsedMilliseconds}ms',
        );
      }
      return (
        ok: false,
        latencyMs: sw.elapsedMilliseconds,
        message: 'HTTP ${resp.statusCode}',
      );
    } on DioException catch (e) {
      sw.stop();
      return (
        ok: false,
        latencyMs: sw.elapsedMilliseconds,
        message: await _dioErrorText(e),
      );
    } catch (e) {
      sw.stop();
      return (ok: false, latencyMs: sw.elapsedMilliseconds, message: '$e');
    }
  }
}
