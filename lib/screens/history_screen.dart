/// 解题历史记录页 - 思谛 STDeel
///
/// 从 drift [SolveRecords] 表读取所有历史记录，按时间倒序列出。
/// 每条卡片默认折叠（题干 + 模型 + 时间 + 反馈标记），点击展开
/// 答案 / 解答过程 / 知识点。反馈按钮就地更新 drift 并同步后端。
///
/// 这是用户在手机上查看历史拍题解题记录的入口。
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../services/sync_service.dart';
import '../widgets/glass.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Future<List<SolveRecordEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppDatabase>().solveRecordDao.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = context.read<AppDatabase>().solveRecordDao.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('解题历史'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<SolveRecordEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '读取历史记录失败：\n${snapshot.error}',
                  style: const TextStyle(color: G.coral, height: 1.5),
                ),
              ),
            );
          }
          final list = snapshot.data ?? const <SolveRecordEntity>[];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: G.textFaint),
                  const SizedBox(height: 12),
                  Text('还没有解题记录', style: TextStyle(color: G.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    '拍照解题后，记录会自动保存到这里',
                    style: TextStyle(fontSize: 12, color: G.textFaint),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _HistoryCard(
                record: list[i],
                onChanged: _refresh,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({required this.record, required this.onChanged});

  final SolveRecordEntity record;
  final VoidCallback onChanged;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  List<String> get _knowledgePoints {
    try {
      final l = jsonDecode(widget.record.knowledgePoints);
      if (l is List) return l.map((e) => e.toString()).toList();
    } catch (_) {}
    return const [];
  }

  /// 按题目状态返回四色标记（颜色 / 图标 / 文案）：
  /// correct=绿(正确) / wrong=红(错误) / retry=蓝(重答) / detail=黄(疑问) / 其余中性(解题)
  (Color, IconData, String) _statusStyle(String action, String feedback) {
    if (feedback == 'correct') {
      return (G.mint, Icons.check_circle_rounded, '正确');
    }
    if (feedback == 'wrong') {
      return (G.coral, Icons.cancel_rounded, '错误');
    }
    switch (action) {
      case 'retry':
        return (G.accent, Icons.refresh_rounded, '重答');
      case 'detail':
        return (G.amber, Icons.help_outline_rounded, '疑问');
      case 'solve':
      default:
        return (G.textFaint, Icons.auto_awesome_rounded, '解题');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    // 四色状态标记：正确=绿 / 错误=红 / 疑问(解答)=黄 / 重答=蓝 / 其余(初始解题)=中性
    final (Color fbColor, IconData fbIcon, String statusLabel) =
        _statusStyle(r.actionType, r.userFeedback);

    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 18,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(fbIcon, size: 18, color: fbColor),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fbColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.questionText.isEmpty ? '（空题干）' : r.questionText,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: G.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (r.aiModel.isNotEmpty) ...[
                              Flexible(
                                child: Text(
                                  r.aiModel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: G.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _formatTime(r.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: G.textFaint,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: G.textFaint,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (r.answer.isNotEmpty) ...[
                  _buildSection('答案', r.answer, color: G.mint),
                  const SizedBox(height: 8),
                ],
                if (r.solution.isNotEmpty) ...[
                  _buildSection('解答', r.solution),
                  const SizedBox(height: 8),
                ],
                if (_knowledgePoints.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final kp in _knowledgePoints)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: G.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: G.accent.withOpacity(0.3)),
                          ),
                          child: Text(
                            kp,
                            style: const TextStyle(
                                fontSize: 11, color: G.accent),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    if (r.latencyMs > 0)
                      _meta('耗时 ${(r.latencyMs / 1000).toStringAsFixed(1)}s'),
                    if (r.tokensUsed > 0) ...[
                      const SizedBox(width: 10),
                      _meta('${r.tokensUsed} tokens'),
                    ],
                    const Spacer(),
                    if (r.synced)
                      _meta('已同步', color: G.textFaint)
                    else
                      _meta('待同步', color: G.amber),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: G.coral,
                          side: BorderSide(
                              color: G.coral.withOpacity(0.4)),
                          minimumSize:
                              const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.cancel_rounded, size: 16),
                        label: const Text('错误'),
                        onPressed: () => _markFeedback('wrong'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: G.mint,
                          minimumSize:
                              const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('正确'),
                        onPressed: () => _markFeedback('correct'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, String body, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color ?? G.textFaint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          body,
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
      ],
    );
  }

  Widget _meta(String text, {Color? color}) => Text(
        text,
        style: TextStyle(fontSize: 10, color: color ?? G.textFaint),
      );

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 就地更新反馈（写 drift + 累计知识点 + 异步同步后端）
  Future<void> _markFeedback(String feedback) async {
    final r = widget.record;
    final db = context.read<AppDatabase>();
    final sync = context.read<SyncService>();
    await db.solveRecordDao.updateFeedback(r.id, feedback);
    final kps = _knowledgePoints;
    final isCorrect = feedback == 'correct';
    for (final kp in kps) {
      await db.knowledgeDao.upsert(
        knowledgePoint: kp,
        deltaCorrect: isCorrect ? 1 : 0,
        deltaWrong: isCorrect ? 0 : 1,
      );
    }
    // 异步上传至后端（失败静默，等下次手动同步重试）
    sync.uploadFeedback(r.id, feedback);
    if (!mounted) return;
    showGlassSnackBar(
      context,
      isCorrect ? '已标记正确，知识点统计已更新' : '已标记错误，薄弱知识点已记录',
      success: true,
    );
    widget.onChanged();
  }
}
