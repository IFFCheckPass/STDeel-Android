/// 设置页 - 思谛 STDeel
///
/// - 后端 URL 配置
/// - AI API Key 配置（组合1 + 组合2）
/// - think 检测超时阈值（默认 15 秒）
/// - 连通性测试按钮
/// - 手动同步按钮
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;
  late TextEditingController _key1Ctrl;
  late TextEditingController _key2Ctrl;
  late TextEditingController _timeoutCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final s = context.read<SettingsProvider>();
    _urlCtrl = TextEditingController(text: s.backendUrl);
    _key1Ctrl = TextEditingController(text: s.apiKeyCombo1);
    _key2Ctrl = TextEditingController(text: s.apiKeyCombo2);
    _timeoutCtrl = TextEditingController(text: s.thinkTimeout.toString());
    _initialized = true;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _key1Ctrl.dispose();
    _key2Ctrl.dispose();
    _timeoutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('后端配置'),
        TextField(
          controller: _urlCtrl,
          decoration: const InputDecoration(
            labelText: '后端 API URL',
            hintText: 'https://api.stdeel.com',
            border: OutlineInputBorder(),
          ),
        ),
        Row(children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => s.setBackendUrl(_urlCtrl.text.trim()),
              child: const Text('保存 URL'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: s.pinging ? null : s.ping,
              child: s.pinging
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.pingOk ? '✅ 已连通' : '连通性测试'),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _sectionTitle('AI API Key'),
        const Text('组合1：Qwen3.5 + Kimi K2.6（NVIDIA NIM）'),
        const SizedBox(height: 8),
        TextField(
          controller: _key1Ctrl,
          decoration: const InputDecoration(
            labelText: 'NVIDIA NIM API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        FilledButton.tonal(
          onPressed: () => s.setApiKeyCombo1(_key1Ctrl.text.trim()),
          child: const Text('保存组合1 Key'),
        ),
        const SizedBox(height: 16),
        const Text('组合2：MathPix OCR + DeepSeek V4'),
        const SizedBox(height: 8),
        TextField(
          controller: _key2Ctrl,
          decoration: const InputDecoration(
            labelText: 'MathPix / DeepSeek API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        FilledButton.tonal(
          onPressed: () => s.setApiKeyCombo2(_key2Ctrl.text.trim()),
          child: const Text('保存组合2 Key'),
        ),
        const SizedBox(height: 24),
        _sectionTitle('think 检测超时阈值'),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _timeoutCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '秒（默认 15）',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => s.setThinkTimeout(
                int.tryParse(_timeoutCtrl.text.trim()) ?? 15),
            child: const Text('保存'),
          ),
        ]),
        const SizedBox(height: 32),
        _sectionTitle('数据同步'),
        FilledButton.icon(
          icon: const Icon(Icons.sync),
          label: const Text('手动同步解题记录至后端'),
          onPressed: () => _manualSync(context),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  Future<void> _manualSync(BuildContext context) async {
    final sync = context.read<SyncService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sync.flushUnsynced();
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ 同步任务已触发（失败项会在下次重试）')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('同步失败：$e')));
    }
  }
}
