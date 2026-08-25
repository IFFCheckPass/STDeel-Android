/// 标准答案库管理页 - 思谛 STDeel
///
/// 列出本地答案库；提供"录入标准答案"功能（题干+答案+知识点），
/// 上传后同步至后端；同时支持搜索匹配。
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../providers/settings_provider.dart';
import '../services/document_split_service.dart';
import '../services/sync_service.dart';
import '../widgets/glass.dart';

class AnswerLibraryScreen extends StatefulWidget {
  const AnswerLibraryScreen({super.key});

  @override
  State<AnswerLibraryScreen> createState() => _AnswerLibraryScreenState();
}

class _AnswerLibraryScreenState extends State<AnswerLibraryScreen> {
  List<AnswerLibraryEntity> _rows = const [];
  bool _loading = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final db = context.read<AppDatabase>();
    final rows = await db.answerLibraryDao.getAll();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _search() async {
    final db = context.read<AppDatabase>();
    final list = _keyword.isEmpty
        ? await db.answerLibraryDao.getAll()
        : await db.answerLibraryDao.searchByText(_keyword);
    if (!mounted) return;
    setState(() => _rows = list);
  }

  Future<void> _showAddDialog() async {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final sCtrl = TextEditingController();
    final kpCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('录入标准答案'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: qCtrl,
                    decoration: const InputDecoration(labelText: '题干')),
                TextField(
                    controller: aCtrl,
                    decoration: const InputDecoration(labelText: '答案')),
                TextField(
                    controller: sCtrl,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: '解答过程')),
                TextField(
                    controller: kpCtrl,
                    decoration: const InputDecoration(
                        labelText: '知识点（逗号分隔）')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('保存')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final sync = context.read<SyncService>();
      final hash = _hashOf(qCtrl.text);
      final kps = kpCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await sync.uploadAnswer(
        questionText: qCtrl.text.trim(),
        questionHash: hash,
        answer: aCtrl.text.trim(),
        solution: sCtrl.text.trim(),
        knowledgePoints: kps,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 已保存到本地答案库并同步后端')),
      );
    } finally {
      qCtrl.dispose();
      aCtrl.dispose();
      sCtrl.dispose();
      kpCtrl.dispose();
    }
  }

  String _hashOf(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  /// 从 PDF / Word 文档导入：AI 自动拆分 → 批量入库答案库。
  Future<void> _importFile() async {
    final models = context.read<SettingsProvider>().buildModelChain();
    if (models.isEmpty) {
      showGlassSnackBar(
        context,
        '请先到「设置 → AI 模型组合」填写 API Key 并启用组合',
        error: true,
      );
      return;
    }
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
    } catch (_) {
      if (!mounted) return;
      showGlassSnackBar(context, '打开文件选择器失败', error: true);
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.single.path;
    if (filePath == null || filePath.isEmpty || !mounted) return;

    // 展示解析中弹窗（不可关闭），完成后关闭
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoadingDialog(),
    );

    final svc = context.read<DocumentSplitService>();
    DocumentSplitResult split;
    try {
      split = await svc.split(path: filePath, models: models);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showGlassSnackBar(context, '文档识别失败：$e', error: true);
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final sync = context.read<SyncService>();
    var saved = 0;
    for (final q in split.questions) {
      final content = q.content.trim();
      if (content.isEmpty) continue;
      await sync.uploadAnswer(
        questionText: content,
        questionHash: _hashOf(content),
        answer: q.answer,
        solution: q.solution,
        knowledgePoints: q.knowledgePoints,
      );
      saved++;
    }
    await _refresh();
    if (!mounted) return;
    showGlassSnackBar(
      context,
      saved == 0
          ? '未从文档中识别到有效题目'
          : '已将 ${split.usedModel} 识别出的 $saved 道题导入答案库',
      success: saved > 0,
      error: saved == 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标准答案库'),
        actions: [
          IconButton(
            tooltip: '从 PDF / Word 导入',
            icon: const Icon(Icons.upload_file),
            onPressed: _importFile,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('录入'),
        onPressed: _showAddDialog,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                labelText: '搜索题干',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
              onChanged: (v) => setState(() => _keyword = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(child: Text('暂无标准答案，点击右下角录入'))
                    : ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          return Card(
                            color: G.glassFill,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: G.glassBorder),
                            ),
                            child: ListTile(
                              title: Text(r.questionText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text('答案：${r.answer}'),
                              trailing: Text('${r.source}'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// 文档解析中的加载弹窗
class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在识别并拆分文档…',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('PDF / Word 将由 AI 自动拆分后导入答案库',
                style: TextStyle(fontSize: 12, color: G.textSecondary)),
          ],
        ),
      ),
    );
  }
}
