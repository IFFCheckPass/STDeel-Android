/// 知识点统计页 - 思谛 STDeel
///
/// - 雷达图展示各知识点掌握度
/// - 薄弱知识点高亮（错误率 > 50%）
/// - 点击知识点查看相关错题
/// - "举一反三"按钮：AI 生成同类变式题
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../models/knowledge_point.dart';
import '../providers/settings_provider.dart';
import '../providers/solve_provider.dart';
import '../widgets/glass.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  List<KnowledgePoint> _points = const [];
  bool _loading = true;
  // null 表示"全部学科"；否则按所选学科过滤
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final db = context.read<AppDatabase>();
    final rows = await db.knowledgeDao.getAll();
    if (!mounted) return;
    setState(() {
      _points = rows
          .map((r) => KnowledgePoint(
                name: r.knowledgePoint,
                subject: r.subject,
                correctCount: r.correctCount,
                wrongCount: r.wrongCount,
              ))
          .toList();
      _loading = false;
    });
  }

  /// 全部学科集合（用于顶部分学科筛选）
  List<String> get _subjects {
    final s = _points.map((p) => p.subject).where((e) => e.isNotEmpty).toSet();
    return s.toList()..sort();
  }

  /// 当前筛选后的知识点（"全部"则不过滤）
  List<KnowledgePoint> get _visible {
    final sel = _selectedSubject;
    if (sel == null || sel.isEmpty) return _points;
    return _points.where((p) => p.subject == sel).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_points.isEmpty) {
      return const Center(
        child: Text('暂无知识点数据，先去解题吧！'),
      );
    }
    final visible = _visible;
    final weak = visible.where((p) => p.isWeak).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('知识点掌握度雷达图',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // 学科筛选
          if (_subjects.isNotEmpty) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _subjectChip(null, label: '全部'),
                  for (final s in _subjects) _subjectChip(s, label: s),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildRadarChart(context, visible),
          const SizedBox(height: 24),
          if (weak.isNotEmpty) ...[
            const Text('薄弱知识点',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: G.coral)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weak
                  .map((p) => ActionChip(
                        label: Text('${p.name}（错误率 ${(p.errorRate * 100).toStringAsFixed(0)}%）'),
                        onPressed: () => _showRelatedWrong(context, p.name),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          const Text('所有知识点（长按可设置学科）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final p in visible) _buildPointRow(context, p),
        ],
      ),
    );
  }

  Widget _subjectChip(String? subject, {required String label}) {
    final selected = _selectedSubject == subject;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        selectedColor: G.accent.withOpacity(0.25),
        checkmarkColor: G.accentFg,
        labelStyle: TextStyle(
          color: selected ? G.accentFg : G.textSecondary,
          fontSize: 13,
        ),
        onSelected: (_) => setState(() => _selectedSubject = subject),
      ),
    );
  }

  Widget _buildRadarChart(BuildContext context, List<KnowledgePoint> source) {
    final n = source.length;
    if (n < 3) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: G.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: G.glassBorder),
        ),
        child: const Text('至少需要 3 个知识点才能绘制雷达图'),
      );
    }
    final values = source.map((p) => p.accuracy * 4).toList();
    return SizedBox(
      height: 240,
      child: RadarChart(RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: [for (final v in values) RadarEntry(value: v)],
            fillColor: G.accentDeep.withOpacity(0.3),
            borderColor: G.accent,
          )
        ],
        titleTextStyle: TextStyle(fontSize: 11, color: G.textSecondary),
        getTitle: (idx, angle) =>
            RadarChartTitle(text: source[idx % n].name),
        tickCount: 4,
        ticksTextStyle: TextStyle(fontSize: 9, color: G.textFaint),
        gridBorderData: BorderSide(color: G.glassBorder),
        radarBackgroundColor: Colors.transparent,
      )),
    );
  }

  Widget _buildPointRow(BuildContext context, KnowledgePoint p) {
    final color = p.isWeak ? G.coral : G.mint;
    return Card(
      color: G.glassFill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: G.glassBorder),
      ),
      child: ListTile(
        onLongPress: () => _manageSubject(context, p),
        title: Text(p.name),
        subtitle: Text(
            '正确 ${p.correctCount} · 错误 ${p.wrongCount} · 正确率 ${(p.accuracy * 100).toStringAsFixed(0)}%'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: G.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: G.accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    p.subject,
                    style: const TextStyle(fontSize: 10, color: G.accent),
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () => _generateVariant(context, p.name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.2),
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.5)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('举一反三'),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showRelatedWrong(context, p.name),
      ),
    );
  }

  /// 知识点的常用学科目录（便于快速归类）
  static const _subjectChoices = <String>[
    '未分类',
    '数学',
    '语文',
    '英语',
    '物理',
    '化学',
    '生物',
    '历史',
    '地理',
    '政治',
    '其他',
  ];

  /// 长按知识点 → 选择/修改学科归属（知识点管理分学科）
  Future<void> _manageSubject(BuildContext context, KnowledgePoint p) async {
    final db = context.read<AppDatabase>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '为「${p.name}」选择学科',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _subjectChoices)
                  ChoiceChip(
                    label: Text(s),
                    selected: p.subject == s,
                    selectedColor: G.accent.withOpacity(0.25),
                    onSelected: (_) => Navigator.pop(context, s),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.pop(context, '未分类'),
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              label: const Text('设为未分类'),
            ),
          ],
        ),
      ),
    );
    if (picked == null || picked.trim().isEmpty || !mounted) return;
    await db.knowledgeDao.setSubject(p.name, picked);
    await _refresh();
  }

  Future<void> _showRelatedWrong(BuildContext context, String kp) async {
    final db = context.read<AppDatabase>();
    final records = await db.solveRecordDao.getByFeedback('wrong');
    if (!context.mounted) return;
    final related =
        records.where((r) => r.knowledgePoints.contains('"$kp"')).toList();
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 320,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('「$kp」相关错题',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (related.isEmpty)
              const Text('暂无错题')
            else
              for (final r in related)
                ListTile(
                  dense: true,
                  title: Text(r.questionText,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('答案：${r.answer}'),
                ),
          ],
        ),
      ),
    );
  }

  /// 举一反三：让 AI 生成同类变式题
  Future<void> _generateVariant(BuildContext context, String kp) async {
    final solve = context.read<SolveProvider>();
    final settings = context.read<SettingsProvider>();
    final models = settings.buildModelChain();
    if (models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先到「设置 → AI 模型组合」配置可用模型')),
      );
      return;
    }
    await solve.askDetailed(
      questionId: 0,
      questionText:
          '请基于「$kp」这一知识点，生成 3 道难度递进的变式题，并给出答案与解析。',
      models: models,
      thinkTimeout: settings.thinkTimeout,
    );
    if (!context.mounted) return;
    if (solve.state.status == SolveStatus.done) {
      Navigator.of(context).pushNamed('/answer');
    }
  }
}
