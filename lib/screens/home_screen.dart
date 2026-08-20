/// 主页 - 思谛 STDeel
///
/// 液态玻璃设计：大按钮（拍照识题 / 从相册选择）
/// 底部导航：首页 / 知识点统计 / 答案库 / 设置
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/solve_provider.dart';
import '../widgets/glass.dart';
import '../widgets/thinking_indicator.dart';
import 'answer_library_screen.dart';
import 'answer_screen.dart';
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

  static const _titles = ['思谛', '知识点统计', '标准答案库', '设置'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomePage(context),
      const KnowledgeScreen(),
      const AnswerLibraryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
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
                    const SizedBox(height: 24),
                    // 品牌 Logo
                    GlassCard(
                      padding: const EdgeInsets.all(28),
                      radius: 28,
                      glowColor: G.accentDeep,
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: G.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: G.accentDeep.withOpacity(0.5),
                                  blurRadius: 28,
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '思谛',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                              color: G.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '拍照识题 · AI 解题 · 多模型自动切换',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: G.textSecondary,
                                  letterSpacing: 1,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    GlassPrimaryButton(
                      icon: Icons.camera_alt_rounded,
                      label: '拍照识题',
                      onPressed: () => _pickImage(context, fromCamera: true),
                    ),
                    const SizedBox(height: 12),
                    GlassPrimaryButton(
                      icon: Icons.photo_library_outlined,
                      label: '从相册选择',
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.06),
                        ],
                      ),
                      borderColor: G.glassBorder,
                      onPressed: () => _pickImage(context, fromCamera: false),
                    ),
                    const SizedBox(height: 12),
                    GlassPrimaryButton(
                      icon: Icons.history,
                      label: '历史记录',
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.06),
                        ],
                      ),
                      borderColor: G.glassBorder,
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/history'),
                    ),
                    const SizedBox(height: 28),
                    if (state.status == SolveStatus.thinking ||
                        state.status == SolveStatus.answering) ...[
                      ThinkingIndicator(
                        isAnswering: state.status == SolveStatus.answering,
                        modelName: state.currentModel.isEmpty
                            ? null
                            : state.currentModel,
                        notice: state.notice,
                      ),
                    ] else if (state.status == SolveStatus.done &&
                        state.result != null)
                      _buildResultSummary(context, state.result!)
                    else if (state.status == SolveStatus.error)
                      GlassCard(
                        fillColor: G.coral.withOpacity(0.08),
                        borderColor: G.coral.withOpacity(0.35),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: G.coral, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '解题失败：${state.error ?? '未知错误'}',
                                style: const TextStyle(
                                    color: G.coral, height: 1.5, fontSize: 13),
                              ),
                            ),
                          ],
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

  Widget _buildResultSummary(BuildContext context, dynamic result) {
    return GlassCard(
      fillColor: G.mint.withOpacity(0.08),
      borderColor: G.mint.withOpacity(0.35),
      glowColor: G.mint,
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: G.mint, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '共识别 ${result.questions.length} 道题，'
              '耗时 ${(result.latencyMs / 1000).toStringAsFixed(1)}s'
              '（${result.aiModel}）',
              style: const TextStyle(color: G.mint, height: 1.4),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/answer'),
            child: const Text('查看'),
          ),
        ],
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
    if (picked == null || picked.isEmpty) return;
    if (!mounted) return;
    // 立即进入 AnswerScreen，由其 initState 触发 solve
    // 并就地展示流式思维链与答案——避免用户困在主页无反馈。
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnswerScreen(imagePath: picked),
      ),
    );
  }
}
