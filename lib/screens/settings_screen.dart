/// 设置页 - 思谛 STDeel
///
/// - AI 模型组合管理（多组合、拖动排序、启用开关）
/// - think 检测超时阈值
/// - 后端 URL 配置 + 连通性测试
/// - 手动同步
/// 所有保存/测试操作均有 SnackBar 反馈。
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_combo.dart';
import '../providers/settings_provider.dart';
import '../services/sync_service.dart';
import '../widgets/glass.dart';
import 'combo_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final s = context.read<SettingsProvider>();
    _urlCtrl = TextEditingController(text: s.backendUrl);
    _initialized = true;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== AI 模型组合 =====
          GlassSectionTitle('AI 模型组合', trailing: Text(
            '${s.availableCombos.length}/${s.combos.length} 可用',
            style: const TextStyle(fontSize: 12, color: G.textSecondary),
          )),
          GlassCard(
            padding: const EdgeInsets.all(12),
            fillColor: G.glassFill.withOpacity(0.5),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: G.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '解题时按顺序自动尝试启用的组合，超时或失败将自动切换下一个。长按卡片可拖动排序。',
                    style: const TextStyle(fontSize: 12, color: G.textSecondary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (s.combos.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  const Icon(Icons.cloud_off, color: G.textFaint, size: 40),
                  const SizedBox(height: 8),
                  const Text('暂无组合，点击下方按钮添加', style: TextStyle(color: G.textSecondary)),
                  TextButton(
                    onPressed: _addCombo,
                    child: const Text('添加组合'),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: s.combos.length,
              onReorder: (oldIndex, newIndex) =>
                  s.moveCombo(oldIndex, newIndex),
              itemBuilder: (context, i) {
                final combo = s.combos[i];
                return _ComboTile(
                  key: ValueKey('combo-${combo.id}'),
                  index: i,
                  combo: combo,
                  onTap: () => _editCombo(combo),
                );
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addCombo,
            icon: const Icon(Icons.add),
            label: const Text('添加组合'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),

          const SizedBox(height: 28),

          // ===== think 超时 =====
          GlassSectionTitle('解题设置'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: G.accent, size: 18),
                    const SizedBox(width: 10),
                    const Text('Think 检测超时', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: G.accentDeep.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${s.thinkTimeout} 秒',
                        style: const TextStyle(
                          color: G.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: s.thinkTimeout.clamp(5, 120).toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  activeColor: G.accent,
                  onChanged: (v) => s.setThinkTimeout(v.round()),
                  onChangeEnd: (v) =>
                      showGlassSnackBar(context, '已保存：超时 ${v.round()} 秒', success: true),
                ),
                const Text(
                  '模型在此时长内未输出任何内容（含思考与回答）时，自动切换下一组合。API 响应慢可适当调大。',
                  style: TextStyle(fontSize: 12, color: G.textFaint, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ===== 后端与数据 =====
          GlassSectionTitle('后端与数据'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: '后端 API URL',
                    hintText: 'https://api.stdeel.com/api/v1',
                    prefixIcon: Icon(Icons.dns_outlined),
                    helperText: '填到 API 根的完整地址（含协议、host 及前缀路径）',
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    '示例：\n'
                    '  · 标准：https://api.stdeel.com/api/v1\n'
                    '  · 反代：https://snserver.dpdns.org/stapi\n'
                    '保存时自动补全协议、去掉尾部斜杠，路径前缀原样保留。',
                    style: TextStyle(fontSize: 11, color: G.textFaint, height: 1.5),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _saveUrl(context, s),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('保存 URL'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: s.pinging ? null : () => _ping(context, s),
                        icon: s.pinging
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering, size: 18),
                        label: const Text('连通性测试'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: G.glassBorder.withOpacity(0.5)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _manualSync(context),
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('手动同步解题记录至后端'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '思谛 STDeel · v0.2.0',
              style: TextStyle(fontSize: 11, color: G.textFaint),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUrl(BuildContext context, SettingsProvider s) async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      showGlassSnackBar(context, 'URL 不能为空', error: true);
      return;
    }
    // 规范化：补全 https://、去尾部斜杠、保留子路径（如 /stapi）
    final normalized = normalizeBaseUrl(url);
    _urlCtrl.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
    await s.setBackendUrl(normalized);
    if (!mounted) return;
    showGlassSnackBar(context, '后端 URL 已保存', success: true);
  }

  Future<void> _ping(BuildContext context, SettingsProvider s) async {
    showGlassSnackBar(context, '正在测试连通性…');
    await s.ping();
    if (!mounted) return;
    if (s.pingOk) {
      showGlassSnackBar(context, '后端连接成功', success: true);
    } else {
      showGlassSnackBar(context, '后端连接失败，请检查 URL 与网络', error: true);
    }
  }

  Future<void> _manualSync(BuildContext context) async {
    final sync = context.read<SyncService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sync.flushUnsynced();
      messenger.showSnackBar(
        const SnackBar(content: Text('同步任务已触发（失败项会在下次重试）')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('同步失败：$e')));
    }
  }

  Future<void> _addCombo() async {
    final preset = await _pickPreset();
    if (preset == null) return;
    await Navigator.of(context).push<AiCombo>(
      MaterialPageRoute(
        builder: (_) => ComboEditScreen(
          initial: AiCombo(
            id: 'combo-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
            name: preset['name'] as String,
            baseUrl: preset['baseUrl'] as String,
            apiKey: '',
            modelId: preset['modelId'] as String,
          ),
          isNew: true,
        ),
      ),
    );
  }

  Future<void> _editCombo(AiCombo combo) async {
    await Navigator.of(context).push<AiCombo>(
      MaterialPageRoute(
        builder: (_) => ComboEditScreen(initial: combo, isNew: false),
      ),
    );
  }

  /// 选择预置模板或空白
  Future<Map<String, String>?> _pickPreset() {
    const presets = <Map<String, String>>[
      {'name': 'DeepSeek', 'baseUrl': 'https://api.deepseek.com/v1', 'modelId': 'deepseek-chat'},
      {'name': '通义千问 VL', 'baseUrl': 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'modelId': 'qwen-vl-plus'},
      {'name': 'NVIDIA NIM', 'baseUrl': 'https://integrate.api.nvidia.com/v1', 'modelId': 'qwen/qwen2.5-vl-72b-instruct'},
      {'name': '智谱 GLM', 'baseUrl': 'https://open.bigmodel.cn/api/paas/v4', 'modelId': 'glm-4v-plus'},
      {'name': '硅基流动', 'baseUrl': 'https://api.siliconflow.cn/v1', 'modelId': 'Qwen/Qwen2.5-VL-72B-Instruct'},
      {'name': '自定义', 'baseUrl': '', 'modelId': ''},
    ];
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('选择预置组合（API Key 均需自行填写）',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            for (final p in presets)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(
                  p['name'] == '自定义' ? Icons.edit_note : Icons.bolt,
                  color: G.accent,
                ),
                title: Text(p['name']!),
                subtitle: p['baseUrl']!.isEmpty ? null : Text(
                  p['baseUrl']!,
                  style: const TextStyle(fontSize: 12, color: G.textFaint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(context, p),
              ),
          ],
        ),
      ),
    );
  }
}

/// 组合卡片（可拖动排序）
class _ComboTile extends StatelessWidget {
  const _ComboTile({
    super.key,
    required this.index,
    required this.combo,
    required this.onTap,
  });

  final int index;
  final AiCombo combo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final ready = combo.enabled && combo.isComplete;

    return Padding(
      // ReorderableListView 不处理 item 间距，用 padding 模拟
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 18,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                // 拖动手柄
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.drag_indicator, color: G.textFaint, size: 20),
                  ),
                ),
                const SizedBox(width: 6),
                // 序号 + 状态
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ready
                        ? G.primaryGradient
                        : null,
                    color: ready ? null : G.glassFillStrong,
                    border: ready ? null : Border.all(color: G.glassBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: ready ? Colors.white : G.textFaint,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 名称 + 详情
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              combo.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!combo.isComplete) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: G.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: G.amber.withOpacity(0.4)),
                              ),
                              child: const Text(
                                '待完善',
                                style: TextStyle(fontSize: 9, color: G.amber),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        combo.modelId.isEmpty ? '未设置模型' : combo.modelId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: G.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: combo.enabled,
                  onChanged: (v) => s.toggleCombo(combo.id, v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
