/// 题目模型 - 思谛 STDeel
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';

class Question {
  Question({
    required this.content,
    List<String>? knowledgePoints,
    this.answer = '',
    this.solution = '',
    this.source = 'ai',
    this.hash,
  }) : knowledgePoints = knowledgePoints ?? const [];

  /// 用题干文本生成 sha256 哈希，用于精确匹配本地答案库
  String get stableHash {
    if (hash != null) return hash!;
    final normalized = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  final String content;
  final List<String> knowledgePoints;
  String answer;
  String solution;
  final String source; // 'ai' | 'answer_library'
  final String? hash;
}
