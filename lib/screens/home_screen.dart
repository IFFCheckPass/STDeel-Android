/// 主页 - 思谛 STDeel
///
/// 大按钮：拍照识题 / 从相册选择
/// 底部导航：首页 / 知识点统计 / 答案库 / 设置
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/solve_provider.dart';
import '../widgets/thinking_indicator.dart';
import 'answer_library_screen.dart';
import 'camera_screen.dart';
import 'knowledge_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['思谛 STDeel', '知识点统计', '标准答案库', '设置'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomePage(context),
      const KnowledgeScreen(),
      const AnswerLibraryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: true,
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '知识点',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: '答案库',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    final solve = context.watch<SolveProvider>();
    final state = solve.state;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 响应式：小屏单栏，宽屏双栏
          final isWide = constraints.maxWidth >= 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Icon(Icons.menu_book,
                        size: 96,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      '拍照识题 · AI 解题',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '直连 NVIDIA NIM · think 检测 Failover',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 40),
                    _primaryButton(
                      context,
                      icon: Icons.camera_alt,
                      label: '拍照识题',
                      onPressed: () => _pickImage(context, fromCamera: true),
                    ),
                    const SizedBox(height: 12),
                    _primaryButton(
                      context,
                      icon: Icons.photo_library,
                      label: '从相册选择',
                      color: const Color(0xFF6C7686),
                      onPressed: () => _pickImage(context, fromCamera: false),
                    ),
                    const SizedBox(height: 32),
                    if (state.status == SolveStatus.thinking ||
                        state.status == SolveStatus.answering)
                      ThinkingIndicator(
                        isAnswering: state.status == SolveStatus.answering,
                        modelName: state.currentModel.isEmpty
                            ? null
                            : state.currentModel,
                      )
                    else if (state.status == SolveStatus.done &&
                        state.result != null)
                      _buildResultSummary(context, state.result!)
                    else if (state.status == SolveStatus.error)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '解题失败：${state.error ?? '未知错误'}',
                          style:
                              const TextStyle(color: Color(0xFFE74C3C)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _primaryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary(BuildContext context, dynamic result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00B894).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '✅ 共识别 ${result.questions.length} 道题，'
        '耗时 ${(result.latencyMs / 1000).toStringAsFixed(1)}s '
        '(${result.aiModel})',
        style: const TextStyle(color: Color(0xFF00B894)),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context, {
    required bool fromCamera,
  }) async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CameraScreen(initialCamera: fromCamera),
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final solve = context.read<SolveProvider>();
    await solve.solve(
      imagePath: picked,
      combo1ApiKey: settings.apiKeyCombo1,
      combo2ApiKey: settings.apiKeyCombo2,
      thinkTimeout: settings.thinkTimeout,
    );
    if (!mounted) return;
    if (solve.state.status == SolveStatus.done) {
      Navigator.of(context).pushNamed('/answer');
    }
  }
}
