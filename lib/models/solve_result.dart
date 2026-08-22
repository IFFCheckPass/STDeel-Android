/// 解题结果模型 - 思谛 STDeel
library;

import 'dart:convert';

/// AI 返回的单道题结果
class QuestionResult {
  QuestionResult({
    required this.id,
    required this.content,
    List<String>? knowledgePoints,
    this.answer = '',
    this.solution = '',
    this.confidence = 0.0,
  }) : knowledgePoints = knowledgePoints ?? const [];

  factory QuestionResult.fromJson(Map<String, dynamic> json) =>
      QuestionResult(
        id: (json['id'] as num?)?.toInt() ?? 0,
        content: (json['content'] as String?) ?? '',
        knowledgePoints: (json['knowledge_points'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        answer: (json['answer'] as String?) ?? '',
        solution: (json['solution'] as String?) ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      );

  final String content;
  final List<String> knowledgePoints;
  String answer;
  String solution;
  double confidence;

  /// 记录 ID：AI 返回阶段通常为 0；解题被持久化后写回漂移(drift)主键，
  /// 供重答/疑问/反馈命中同一历史记录。
  int id;

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'knowledge_points': knowledgePoints,
        'answer': answer,
        'solution': solution,
        'confidence': confidence,
      };
}

/// 一次完整解题会话的结果（多道题）
class SolveResult {
  SolveResult({
    required this.questions,
    required this.aiModel,
    required this.latencyMs,
    required this.tokensUsed,
    required this.source,
    this.imagePath = '',
    this.error,
  });

  final List<QuestionResult> questions;
  final String aiModel;
  final int latencyMs;
  final int tokensUsed;

  /// 'ai' | 'answer_library' | 'error'
  final String source;
  final String imagePath;
  final String? error;

  bool get isSuccess => error == null && questions.isNotEmpty;

  /// 兼容后端上传用的 JSON 串
  String toJsonString() => jsonEncode({
        'ai_model': aiModel,
        'latency_ms': latencyMs,
        'tokens_used': tokensUsed,
        'source': source,
        'image_path': imagePath,
        'questions':
            questions.map((q) => q.toJson()).toList(growable: false),
      });
}
