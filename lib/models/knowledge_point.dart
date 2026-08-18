/// 知识点模型 - 思谛 STDeel
library;

class KnowledgePoint {
  KnowledgePoint({
    required this.name,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  /// 总题数
  int get totalCount => correctCount + wrongCount;

  /// 正确率 0.0 ~ 1.0
  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;

  /// 错误率 0.0 ~ 1.0
  double get errorRate => totalCount == 0 ? 0 : wrongCount / totalCount;

  /// 是否薄弱（错误率 > 50% 且至少有 1 题记录）
  bool get isWeak =>
      totalCount > 0 && errorRate > 0.5;

  final String name;
  final int correctCount;
  final int wrongCount;

  KnowledgePoint copyWith({int? correctCount, int? wrongCount}) =>
      KnowledgePoint(
        name: name,
        correctCount: correctCount ?? this.correctCount,
        wrongCount: wrongCount ?? this.wrongCount,
      );
}
