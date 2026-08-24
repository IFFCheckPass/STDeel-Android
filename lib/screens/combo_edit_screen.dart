/// AI 组合编辑页 - 思谛 STDeel
///
/// 每个组合包含：
///   - 名称
///   - Base URL（OpenAI 兼容端点）
///   - API Key（可显示/隐藏）
///   - Model ID（手动输入 或 从接口拉取模型列表选择）
/// 以及连通性测试（返回延迟/错误详情）。
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_combo.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../widgets/glass.dart';

class ComboEditScreen extends StatefulWidget {
  const ComboEditScreen({
    super.key,
    required this.initial,
    required this.isNew,
  });

  final AiCombo initial;
  final bool isNew;

  @override
  State<ComboEditScreen> createState() => _ComboEditScreenState();
}

class _ComboEditScreenState extends State<ComboEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;
  late final TextEditingController _modelCtrl;

  bool _obscureKey = true;
  bool _fetchingModels = false;
  bool _testing = false;

  /// 测试结果：(ok, latencyMs, message)
  ({bool ok, int latencyMs, String message})? _testResult;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.name);
    _urlCtrl = TextEditingController(text: widget.initial.baseUrl);
    _keyCtrl = TextEditingController(text: widget.initial.apiKey);
    _modelCtrl = TextEditingController(text: widget.initial.modelId);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  AiCombo _buildCombo() => AiCombo(
        id: widget.initial.id,
        name: _nameCtrl.text.trim().isEmpty
            ? '未命名组合'
            : _nameCtrl.text.trim(),
        baseUrl: normalizeBaseUrl(_urlCtrl.text),
        apiKey: _keyCtrl.text.trim(),
        modelId: _modelCtrl.text.trim(),
        enabled: widget.initial.enabled,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? '添加 AI 组合' : '编辑 AI 组合'),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: '删除组合',
              icon: const Icon(Icons.delete_outline, color: G.coral),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== 基础信息 =====
            GlassSectionTitle('基础信息'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '组合名称',
                      hintText: '如：DeepSeek、组合一',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.deepseek.com/v1',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keyCtrl,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-...',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== 模型 =====
            GlassSectionTitle('模型'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Model ID',
                      hintText: 'deepseek-chat（可手动输入）',
                      prefixIcon: Icon(Icons.smart_toy_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _fetchingModels ? null : _fetchModels,
                    icon: _fetchingModels
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined, size: 18),
                    label: Text(_fetchingModels ? '正在获取模型列表…' : '获取模型列表'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== 连通性测试 =====
            GlassSectionTitle('连通性测试'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check, size: 18),
                    label: Text(_testing ? '测试中…' : '测试连通性'),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_testResult!.ok ? G.mint : G.coral)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_testResult!.ok ? G.mint : G.coral)
                              .withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _testResult!.ok
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _testResult!.ok ? G.mint : G.coral,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _testResult!.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: _testResult!.ok ? G.mint : G.coral,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ===== 保存 =====
            GlassPrimaryButton(
              icon: Icons.check_rounded,
              label: '保存组合',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchModels() async {
    final baseUrl = normalizeBaseUrl(_urlCtrl.text);
    final apiKey = _keyCtrl.text.trim();
    if (baseUrl.isEmpty) {
      showGlassSnackBar(context, '请先填写 Base URL', error: true);
      return;
    }
    setState(() {
      _fetchingModels = true;
    });
    try {
      final ai = context.read<AiService>();
      final models = await ai.fetchModels(baseUrl: baseUrl, apiKey: apiKey);
      if (!mounted) return;
      if (models.isEmpty) {
        showGlassSnackBar(context, '该端点未返回任何模型', error: true);
        return;
      }
      final selected = await _showModelPicker(models);
      if (selected != null && selected.isNotEmpty) {
        _modelCtrl.text = selected;
        showGlassSnackBar(context, '已选择模型：$selected', success: true);
      }
    } catch (e) {
      if (!mounted) return;
      showGlassSnackBar(context, '获取模型列表失败：$e', error: true);
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  Future<String?> _showModelPicker(List<String> models) {
    var keyword = '';
    var filtered = models;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          filtered = models
              .where((m) =>
                  m.toLowerCase().contains(keyword.toLowerCase()))
              .toList();
          return SizedBox(
            height: MediaQuery.of(sheetCtx).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '选择模型',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      Text(
                        '${models.length} 个模型',
                        style: TextStyle(fontSize: 12, color: G.textFaint),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: false,
                    decoration: const InputDecoration(
                      hintText: '搜索模型…',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        setSheetState(() => keyword = v),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final m = filtered[i];
                      final selected = m == _modelCtrl.text;
                      return ListTile(
                        dense: true,
                        title: Text(
                          m,
                          style: TextStyle(
                            fontSize: 13,
                            color: selected ? G.accent : G.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check, color: G.accent, size: 18)
                            : null,
                        onTap: () => Navigator.pop(sheetCtx, m),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _testConnection() async {
    final combo = _buildCombo();
    if (combo.baseUrl.isEmpty) {
      showGlassSnackBar(context, '请先填写 Base URL', error: true);
      return;
    }
    if (combo.modelId.isEmpty) {
      showGlassSnackBar(context, '请先填写 Model ID', error: true);
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final ai = context.read<AiService>();
      final result = await ai.testConnection(
        baseUrl: combo.baseUrl,
        apiKey: combo.apiKey,
        modelId: combo.modelId,
      );
      if (!mounted) return;
      setState(() => _testResult = result);
      showGlassSnackBar(
        context,
        result.ok ? result.message : '测试失败：${result.message}',
        success: result.ok,
        error: !result.ok,
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final combo = _buildCombo();
    if (combo.baseUrl.isEmpty) {
      showGlassSnackBar(context, 'Base URL 不能为空', error: true);
      return;
    }
    if (combo.apiKey.isEmpty) {
      showGlassSnackBar(context, 'API Key 不能为空', error: true);
      return;
    }
    if (combo.modelId.isEmpty) {
      showGlassSnackBar(context, 'Model ID 不能为空', error: true);
      return;
    }
    final s = context.read<SettingsProvider>();
    await s.saveCombo(combo);
    if (!mounted) return;
    showGlassSnackBar(context, '组合「${combo.name}」已保存', success: true);
    Navigator.of(context).pop(combo);
  }

  Future<void> _delete() async {
    final combo = widget.initial;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除组合'),
        content: Text('确定删除「${combo.name}」吗？该操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: G.coral,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final s = context.read<SettingsProvider>();
    await s.deleteCombo(combo.id);
    if (!mounted) return;
    showGlassSnackBar(context, '组合「${combo.name}」已删除', success: true);
    Navigator.of(context).pop();
  }
}
