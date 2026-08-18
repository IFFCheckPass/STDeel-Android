/// 答案展示页 - 思谛 STDeel（核心页面）
///
/// 整页可上下滚动；每道题一个 AnswerCard：
///   - 左侧 4 个按钮（竖向）：重答 / 疑问 / 错误 / 正确
///   - 右侧：题目 + 知识点标签 + 答案 + 解答过程（LaTeX）
/// 使用 flutter_gen_ai_chat_ui 展示流式动画，flutter_tex 渲染公式。
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/solve_result.dart';
import '../providers/settings_provider.dart';
import '../providers/solve_provider.dart';
import '../widgets/answer_card.dart';
import '../widgets/thinking_indicator.dart';

class AnswerScreen extends StatelessWidget {
  const AnswerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final solve = context.watch<SolveProvider>();
    final state = solve.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('解题结果'),
        centerTitle: true,
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, SolveUiState state) {
    if (state.status == SolveStatus.thinking ||
        state.status == SolveStatus.answering) {
      return _buildStreaming(context, state);
    }
    if (state.status == SolveStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Color(0xFFE74C3C)),
              const SizedBox(height: 12),
              Text(state.error ?? '未知错误',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE74C3C))),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }
    final result = state.result;
    if (result == null || result.questions.isEmpty) {
      return const Center(child: Text('暂无解题结果'));
    }
    return _buildResults(context, result.questions, state.currentModel);
  }

  Widget _buildStreaming(BuildContext context, SolveUiState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ThinkingIndicator(
            isAnswering: state.status == SolveStatus.answering,
            modelName: state.currentModel.isEmpty
                ? null
                : state.currentModel,
          ),
          const SizedBox(height: 12),
          if (state.status == SolveStatus.thinking &&
              state.reasoningText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4F7CFF).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                state.reasoningText,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (state.status == SolveStatus.answering &&
              state.answerText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(state.answerText),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    List<QuestionResult> questions,
    String modelName,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final q in questions)
            AnswerCard(
              question: q,
              modelName: modelName,
              feedback: 'none',
              onRetry: () => _onRetry(context, q),
              onAskDetailed: () => _onAskDetailed(context, q),
              onMarkCorrect: () => _onMarkCorrect(context, q),
              onMarkWrong: () => _onMarkWrong(context, q),
            ),
        ],
      ),
    );
  }

  Future<void> _onRetry(BuildContext context, QuestionResult q) async {
    final solve = context.read<SolveProvider>();
    final settings = context.read<SettingsProvider>();
    await solve.retry(
      questionId: q.id,
      questionText: q.content,
      combo1ApiKey: settings.apiKeyCombo1,
      combo2ApiKey: settings.apiKeyCombo2,
      thinkTimeout: settings.thinkTimeout,
    );
  }

  Future<void> _onAskDetailed(BuildContext context, QuestionResult q) async {
    final solve = context.read<SolveProvider>();
    final settings = context.read<SettingsProvider>();
    await solve.askDetailed(
      questionId: q.id,
      questionText: q.content,
      combo1ApiKey: settings.apiKeyCombo1,
      combo2ApiKey: settings.apiKeyCombo2,
      thinkTimeout: settings.thinkTimeout,
    );
  }

  Future<void> _onMarkCorrect(BuildContext context, QuestionResult q) async {
    final solve = context.read<SolveProvider>();
    await solve.markCorrect(
      questionId: q.id,
      knowledgePoints: q.knowledgePoints,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已标记正确，知识点统计已更新')),
    );
  }

  Future<void> _onMarkWrong(BuildContext context, QuestionResult q) async {
    final solve = context.read<SolveProvider>();
    await solve.markWrong(
      questionId: q.id,
      knowledgePoints: q.knowledgePoints,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已标记错误，薄弱知识点已记录')),
    );
  }
}
