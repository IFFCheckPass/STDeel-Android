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

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  List<KnowledgePoint> _points = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final db = context.read<AppDatabase>();
    final rows = await db.knowledgeDao.getAll();
    setState(() {
      _points = rows
          .map((r) => KnowledgePoint(
                name: r.knowledgePoint,
                correctCount: r.correctCount,
                wrongCount: r.wrongCount,
              ))
          .toList();
      _loading = false;
    });
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
    final weak = _points.where((p) => p.isWeak).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('知识点掌握度雷达图',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildRadarChart(context),
          const SizedBox(height: 24),
          if (weak.isNotEmpty) ...[
            const Text('薄弱知识点',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE74C3C))),
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
          const Text('所有知识点',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final p in _points) _buildPointRow(context, p),
        ],
      ),
    );
  }

  Widget _buildRadarChart(BuildContext context) {
    final n = _points.length;
    if (n < 3) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('至少需要 3 个知识点才能绘制雷达图'),
      );
    }
    final values = _points.map((p) => p.accuracy * 4).toList();
    return SizedBox(
      height: 240,
      child: RadarChart(RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: [for (final v in values) RadarEntry(value: v)],
            fillColor: const Color(0xFF4F7CFF).withOpacity(0.3),
            borderColor: const Color(0xFF4F7CFF),
          )
        ],
        titleTextStyle: const TextStyle(
            fontSize: 11, color: Color(0xFF555555)),
        getTitle: (idx, angle) =>
            RadarChartTitle(text: _points[idx % n].name),
        tickCount: 4,
        ticksTextStyle: const TextStyle(fontSize: 9, color: Color(0xFFAAAAAA)),
        gridBorderData: BorderSide(color: Colors.grey.shade300),
        radarBackgroundColor: Colors.transparent,
      )),
    );
  }

  Widget _buildPointRow(BuildContext context, KnowledgePoint p) {
    final color = p.isWeak ? const Color(0xFFE74C3C) : const Color(0xFF00B894);
    return Card(
      child: ListTile(
        title: Text(p.name),
        subtitle: Text(
            '正确 ${p.correctCount} · 错误 ${p.wrongCount} · 正确率 ${(p.accuracy * 100).toStringAsFixed(0)}%'),
        trailing: ElevatedButton(
          onPressed: () => _generateVariant(context, p.name),
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: const Text('举一反三', style: TextStyle(color: Colors.white)),
        ),
        onTap: () => _showRelatedWrong(context, p.name),
      ),
    );
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
    await solve.askDetailed(
      questionId: 0,
      questionText:
          '请基于「$kp」这一知识点，生成 3 道难度递进的变式题，并给出答案与解析。',
      combo1ApiKey: settings.apiKeyCombo1,
      thinkTimeout: settings.thinkTimeout,
    );
    if (!context.mounted) return;
    if (solve.state.status == SolveStatus.done) {
      Navigator.of(context).pushNamed('/answer');
    }
  }
}
