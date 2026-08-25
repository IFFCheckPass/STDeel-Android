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
import '../services/backend_api.dart';
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
  late TextEditingController _usernameCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final s = context.read<SettingsProvider>();
    _urlCtrl = TextEditingController(text: s.backendUrl);
    _usernameCtrl = TextEditingController(text: s.username ?? '');
    _initialized = true;
  }

  @override
  void dispose() {
    // 仅在 didChangeDependencies 中初始化；若在首次构建前即被 dispose（极端情况下），
    // 跳过释放以免抛 LateInitializationError。
    if (_initialized) {
      _urlCtrl.dispose();
      _usernameCtrl.dispose();
    }
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
            style: TextStyle(fontSize: 12, color: G.textSecondary),
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
                    style: TextStyle(fontSize: 12, color: G.textSecondary, height: 1.5),
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
                  Icon(Icons.cloud_off, color: G.textFaint, size: 40),
                  const SizedBox(height: 8),
                  Text('暂无组合，点击下方按钮添加', style: TextStyle(color: G.textSecondary)),
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
                        style: TextStyle(
                          color: G.accentFg,
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
                Text(
                  '模型在此时长内未输出任何内容（含思考与回答）时，自动切换下一组合。API 响应慢可适当调大。',
                  style: TextStyle(fontSize: 12, color: G.textFaint, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ===== 外观（日/夜） =====
          GlassSectionTitle('外观'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.contrast_rounded, color: G.accent, size: 18),
                    const SizedBox(width: 10),
                    const Text('主题模式', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(
                      s.themeMode == ThemeMode.system
                          ? Icons.brightness_auto
                          : Icons.palette_outlined,
                      color: G.accent,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('日间'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('跟随系统'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('夜间'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (sel) => s.setThemeMode(sel.first),
                    showSelectedIcon: false,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '日间模式采用浅色玻璃卡片；也可自动跟随系统深浅色。',
                  style: TextStyle(fontSize: 12, color: G.textFaint, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ===== 账号绑定 =====
          GlassSectionTitle('账户'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: G.accent, size: 18),
                    const SizedBox(width: 10),
                    const Text('用户名', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (s.username != null && s.username!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: G.mint.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: G.mint.withOpacity(0.4)),
                        ),
                        child: const Text('已绑定', style: TextStyle(fontSize: 10, color: G.mint)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    hintText: '例如：张三 / student01',
                    prefixIcon: Icon(Icons.badge_outlined),
                    helperText: '设置用户名并绑定账号后，多设备用同一用户名即可共享同一份数据',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _saveUsername(context, s),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('绑定 / 同步'),
                ),
                const SizedBox(height: 8),
                Text(
                  '绑定后会把本机已配置的 AI API Key 一并上传到该账号，换设备登录后自动拉回。',
                  style: TextStyle(fontSize: 11, color: G.textFaint, height: 1.5),
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
                // 公网 / 内网 通道切换
                Row(
                  children: [
                    const Icon(Icons.public, color: G.accent, size: 18),
                    const SizedBox(width: 10),
                    const Text('后端通道', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('公网'),
                      icon: Icon(Icons.cloud_outlined),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('内网'),
                      icon: Icon(Icons.router_outlined),
                    ),
                  ],
                  selected: {s.usePublicBackend},
                  onSelectionChanged: (sel) =>
                      _selectChannel(context, s, sel.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: s.usePublicBackend ? '公网 API URL' : '内网 API URL',
                    hintText: s.usePublicBackend
                        ? 'https://api.stdeel.com/api/v1'
                        : 'http://192.168.1.10:8000/api/v1',
                    prefixIcon: Icon(
                      s.usePublicBackend ? Icons.public : Icons.apartment,
                    ),
                    helperText: '内网支持 http 协议与端口号，如 http://192.168.1.10:8000/api/v1',
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    '示例：\n'
                    '  · 公网：https://api.stdeel.com/api/v1\n'
                    '  · 内网：http://192.168.x.x:8000/api/v1（同网段直连调试）\n'
                    '保存时自动补全协议、去掉尾部斜杠，路径前缀与端口号原样保留。',
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
                  label: const Text('手动同步解题记录（双向）'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '思谛 STDeel · v0.5.5',
              style: TextStyle(fontSize: 11, color: G.textFaint),
            ),
          ),
        ],
      ),
    );
  }

  /// 绑定 / 同步：设置用户名 → 后端按 username 找或创建用户 → 上传 AI API Key
  Future<void> _saveUsername(BuildContext context, SettingsProvider s) async {
    final name = _usernameCtrl.text.trim();
    if (name.isEmpty) {
      showGlassSnackBar(context, '请输入用户名', error: true);
      return;
    }
    showGlassSnackBar(context, '正在绑定账号…');
    final ok = await s.setUsername(name);
    if (!mounted) return;
    if (ok) {
      showGlassSnackBar(context, '账号绑定成功', success: true);
      // 上传本机 AI API Key 到账号（跨端同步）
      final keys = <String, String>{};
      for (final c in s.combos) {
        if (c.isComplete && c.apiKey.trim().isNotEmpty) {
          keys[c.name] = c.apiKey.trim();
        }
      }
      final api = context.read<BackendApi>();
      final okKey = await api.syncUserApiKeys(keys);
      if (mounted && !okKey) {
        showGlassSnackBar(
          context,
          '用户名已绑定，但 API Key 同步失败（可稍后重试）',
          error: true,
        );
      }
    } else {
      showGlassSnackBar(
        context,
        '后端绑定未成功（后端未适配或网络异常），用户名已保存在本机',
        error: true,
      );
    }
  }

  /// 切换公网/内网通道时，把输入框内容切到对应通道的已保存 URL
  void _selectChannel(BuildContext context, SettingsProvider s, bool usePublic) {
    if (s.usePublicBackend == usePublic) return;
    s.setUsePublicBackend(usePublic);
    final target = usePublic ? s.backendUrlPublic : s.backendUrlIntranet;
    _urlCtrl.value = TextEditingValue(
      text: target.isEmpty ? '' : target,
      selection: TextSelection.collapsed(offset: target.length),
    );
  }

  Future<void> _saveUrl(BuildContext context, SettingsProvider s) async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      showGlassSnackBar(context, 'URL 不能为空', error: true);
      return;
    }
    // 规范化：补全 https://、去尾部斜杠、保留子路径与端口号
    final normalized = normalizeBaseUrl(url);
    _urlCtrl.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
    if (s.usePublicBackend) {
      await s.setBackendUrlPublic(normalized);
      showGlassSnackBar(context, '公网后端 URL 已保存', success: true);
    } else {
      await s.setBackendUrlIntranet(normalized);
      showGlassSnackBar(context, '内网后端 URL 已保存', success: true);
    }
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
      // 双向同步：先上传本地未同步记录，再下拉后端缺失记录
      final result = await sync.syncAll();
      final msg = result.hasFailure
          ? '同步完成：上传成功 ${result.uploaded} 条、失败 ${result.uploadFailed} 条，回写 ${result.pulled} 条'
          : '同步成功：上传 ${result.uploaded} 条，回写 ${result.pulled} 条';
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: result.hasFailure ? G.coral : G.mint,
        ),
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
                  style: TextStyle(fontSize: 12, color: G.textFaint),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
                          if (combo.multimodal) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: G.mint.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: G.mint.withOpacity(0.4)),
                              ),
                              child: const Text(
                                '多模态',
                                style: TextStyle(fontSize: 9, color: G.mint),
                              ),
                            ),
                          ],
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
                        style: TextStyle(fontSize: 12, color: G.textSecondary),
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
