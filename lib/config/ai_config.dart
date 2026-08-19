/// AI 调用配置 - 思谛 STDeel
///
/// 模型组合由用户在设置页自由配置（见 [AiCombo]），
/// 本文件仅保留单模型调用配置与提示词。
library;

/// 单个 AI 模型的调用配置（由 AiCombo 生成）
class AiModelConfig {
  const AiModelConfig({
    required this.name,
    required this.model,
    required this.endpoint,
    required this.apiKey,
  });

  /// 模型人类可读名（用于通知/UI，一般为组合名）
  final String name;

  /// 调用 API 时使用的 model 字段
  final String model;

  /// OpenAI 兼容端点（不含 /chat/completions 后缀，已规范化）
  final String endpoint;

  /// API Key
  final String apiKey;
}

class AiConfig {
  AiConfig._();

  /// 系统提示词：要求 AI 返回结构化 JSON
  static const String systemPrompt = '''
你是一个数学解题助手。请分析图片中的题目，返回 JSON 格式：
{"questions": [{"id": 1, "content": "题目内容", "knowledge_points": ["知识点1","知识点2"], "answer": "答案", "solution": "简略解答过程", "confidence": 0.95}]}
如果图片中有多道题，请在 questions 数组中分别返回。
仅返回 JSON，不要附加任何解释性文字。
''';

  /// 附加"详细分步解答"指令（疑问按钮）
  static const String detailedSolutionSuffix =
      '。请给出详细分步解答，每一步都要清晰说明。';

  /// 重答时使用的温度参数（覆盖当前答案）
  static const double retryTemperature = 0.9;
}
