/// 基础冒烟测试 - 思谛 STDeel
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:stdeel/models/ai_combo.dart';

void main() {
  test('AiCombo JSON 序列化往返', () {
    final combo = AiCombo(
      id: 'test-1',
      name: 'Test',
      baseUrl: 'https://api.example.com/v1/',
      apiKey: 'sk-test',
      modelId: 'test-model',
      enabled: true,
    );
    final json = combo.toJson();
    final restored = AiCombo.fromJson(json);
    expect(restored.name, combo.name);
    expect(restored.apiKey, combo.apiKey);
    expect(restored.modelId, combo.modelId);
    expect(restored.enabled, combo.enabled);
  });

  test('normalizeBaseUrl 补全协议并去尾部斜杠', () {
    expect(normalizeBaseUrl('api.example.com/v1/'),
        'https://api.example.com/v1');
    expect(normalizeBaseUrl('https://api.example.com/v1/'),
        'https://api.example.com/v1');
    expect(normalizeBaseUrl('http://a.b/c//'), 'http://a.b/c');
    expect(normalizeBaseUrl(''), '');
  });
}
