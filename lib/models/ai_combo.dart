/// AI 模型组合 - 思谛 STDeel
///
/// 用户可自由添加任意数量的 AI 组合，每个组合包含：
///   - Base URL（OpenAI 兼容端点）
///   - API Key
///   - Model ID（可通过 /models 接口获取，也可手动输入）
///
/// 解题时按列表顺序依次尝试（Failover），某个组合未在限时内
/// 开始思考或请求失败时自动切换到下一个。
library;

import '../config/ai_config.dart';

class AiCombo {
  AiCombo({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
    this.enabled = true,
  });

  /// 唯一标识
  final String id;

  /// 组合名称（用户可改）
  String name;

  /// OpenAI 兼容 Base URL，如 https://api.deepseek.com/v1
  String baseUrl;

  /// API Key
  String apiKey;

  /// 模型 ID，如 deepseek-chat
  String modelId;

  /// 是否参与 Failover 链
  bool enabled;

  bool get isComplete =>
      baseUrl.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      modelId.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'modelId': modelId,
        'enabled': enabled,
      };

  factory AiCombo.fromJson(Map<String, dynamic> json) => AiCombo(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '未命名组合',
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        modelId: json['modelId'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  AiCombo copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? modelId,
    bool? enabled,
  }) =>
      AiCombo(
        id: id ?? this.id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        modelId: modelId ?? this.modelId,
        enabled: enabled ?? this.enabled,
      );

  /// 转成 AI 调用配置
  AiModelConfig toModelConfig() => AiModelConfig(
        name: name,
        model: modelId.trim(),
        endpoint: normalizeBaseUrl(baseUrl),
        apiKey: apiKey.trim(),
      );
}

/// 规范化 Base URL：补全协议、去尾部斜杠
String normalizeBaseUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) return '';
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

/// 预置默认组合（API Key 留空，由用户填写）
List<AiCombo> defaultAiCombos() => [
      AiCombo(
        id: 'preset-deepseek',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: '',
        modelId: 'deepseek-chat',
      ),
      AiCombo(
        id: 'preset-qwen-vl',
        name: '通义千问 VL',
        baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        apiKey: '',
        modelId: 'qwen-vl-plus',
      ),
      AiCombo(
        id: 'preset-nim',
        name: 'NVIDIA NIM',
        baseUrl: 'https://integrate.api.nvidia.com/v1',
        apiKey: '',
        modelId: 'qwen/qwen2.5-vl-72b-instruct',
      ),
    ];
