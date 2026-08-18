/// AI API 双组合配置 - 思谛 STDeel
///
/// 组合1（默认）：Qwen3.5 主模型 + Kimi K2.6 备用，均走 NVIDIA NIM 端点
/// 组合2（降级兜底）：MathPix OCR → DeepSeek V4 两阶段
///
/// 所有模型通过 OpenAI 兼容 API 调用。
class AiModelConfig {
  const AiModelConfig({
    required this.name,
    required this.model,
    required this.endpoint,
    required this.apiKey,
    this.enableThinking = false,
    this.stage = 0,
  });

  /// 模型人类可读名（用于通知/UI）
  final String name;

  /// 调用 API 时使用的 model 字段
  final String model;

  /// OpenAI 兼容端点（不含 /chat/completions 后缀）
  final String endpoint;

  /// API Key
  final String apiKey;

  /// Kimi 需显式开启 thinking，Qwen3.5 默认开启
  final bool enableThinking;

  /// 两阶段调用中的阶段索引（0=单阶段，1=OCR，2=求解）
  final int stage;

  AiModelConfig copyWith({String? apiKey, String? endpoint}) =>
      AiModelConfig(
        name: name,
        model: model,
        endpoint: endpoint ?? this.endpoint,
        apiKey: apiKey ?? this.apiKey,
        enableThinking: enableThinking,
        stage: stage,
      );
}

class AiComboConfig {
  const AiComboConfig({
    required this.id,
    required this.label,
    required this.stages,
  });

  /// 组合标识
  final int id;

  /// 组合描述
  final String label;

  /// 按顺序执行的阶段，单模型组合只有 1 个 stage
  /// 两阶段组合（MathPix→DeepSeek）有 2 个 stage
  final List<AiModelConfig> stages;
}

class AiConfig {
  AiConfig._();

  /// 组合1（默认）
  /// 主模型：Qwen3.5-397B-A17B（NVIDIA NIM）
  /// 备用：Kimi K2.6（同端点，需显式 thinking）
  static AiComboConfig combo1(String apiKey, {String? endpoint}) {
    final baseEndpoint = endpoint ?? 'https://integrate.api.nvidia.com/v1';
    return AiComboConfig(
      id: 1,
      label: '组合1：Qwen3.5 + Kimi K2.6',
      stages: [
        AiModelConfig(
          name: 'Qwen3.5-397B-A17B',
          model: 'qwen3.5-397b-a17b',
          endpoint: baseEndpoint,
          apiKey: apiKey,
          enableThinking: false, // Qwen3.5 默认开启
          stage: 0,
        ),
        AiModelConfig(
          name: 'Kimi K2.6',
          model: 'kimi-k2.6',
          endpoint: baseEndpoint,
          apiKey: apiKey,
          enableThinking: true, // Kimi 需显式开启
          stage: 0,
        ),
      ],
    );
  }

  /// 组合2（降级兜底）—— 两阶段
  /// 第一阶段：MathPix OCR（图片→LaTeX）
  /// 第二阶段：DeepSeek V4（LaTeX→答案）
  static AiComboConfig combo2(String apiKey, {String? endpoint}) {
    final baseEndpoint = endpoint ?? 'https://integrate.api.nvidia.com/v1';
    return AiComboConfig(
      id: 2,
      label: '组合2：MathPix OCR + DeepSeek V4',
      stages: [
        AiModelConfig(
          name: 'MathPix OCR',
          model: 'mathpix-ocr',
          endpoint: baseEndpoint,
          apiKey: apiKey,
          stage: 1, // OCR 阶段
        ),
        AiModelConfig(
          name: 'DeepSeek V4',
          model: 'deepseek-v4',
          endpoint: baseEndpoint,
          apiKey: apiKey,
          enableThinking: false,
          stage: 2, // 求解阶段
        ),
      ],
    );
  }

  /// 系统提示词：要求 AI 返回结构化 JSON
  static const String systemPrompt = '''
你是一个数学解题助手。请分析图片中的题目，返回 JSON 格式：
{"questions": [{"id": 1, "content": "题目内容", "knowledge_points": ["知识点1","知识点2"], "answer": "答案", "solution": "简略解答过程", "confidence": 0.95}]}
如果图片中有多道题，请在 questions 数组中分别返回。
仅返回 JSON，不要附加任何解释性文字。
''';

  /// 第二阶段（DeepSeek）使用纯文本输入时的提示词模板
  static String solutionPrompt(String latexText) =>
      '请基于以下题目的 LaTeX 表达，给出答案与解答过程，返回 JSON：\n$latexText';

  /// 附加"详细分步解答"指令（疑问按钮）
  static const String detailedSolutionSuffix =
      '。请给出详细分步解答，每一步都要清晰说明。';

  /// 重答时使用的温度参数（覆盖当前答案）
  static const double retryTemperature = 0.9;
}
