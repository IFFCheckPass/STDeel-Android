/// 标准答案库管理页 - 思谛 STDeel
///
/// 列出本地答案库；提供"录入标准答案"功能（题干+答案+知识点），
/// 上传后同步至后端；同时支持搜索匹配。
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../services/sync_service.dart';

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
    setState(() => _rows = list);
  }

  Future<void> _showAddDialog() async {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final sCtrl = TextEditingController();
    final kpCtrl = TextEditingController();

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
    if (ok != true) return;
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
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 已保存到本地答案库并同步后端')),
    );
  }

  String _hashOf(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('标准答案库')),
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
