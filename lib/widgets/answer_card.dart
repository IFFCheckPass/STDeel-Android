/// 答案卡片 - 思谛 STDeel
///
/// 每道题一个卡片。左侧竖向 4 个按钮：
///   - 重答（蓝色 #4f7cff）
///   - 疑问（黄色 #f5a623）
///   - 错误（红色 #e74c3c）
///   - 正确（绿色 #00b894）
/// 右侧：题目 + 知识点标签 + 答案 + 解答过程（LaTeX 渲染）
library;

import 'package:flutter/material.dart';

import '../models/solve_result.dart';
import 'latex_renderer.dart';

class AnswerCard extends StatelessWidget {
  const AnswerCard({
    super.key,
    required this.question,
    required this.modelName,
    required this.onRetry,
    required this.onAskDetailed,
    required this.onMarkCorrect,
    required this.onMarkWrong,
    this.feedback = 'none',
    this.isLoading = false,
  });

  final QuestionResult question;
  final String modelName;
  final VoidCallback onRetry;
  final VoidCallback onAskDetailed;
  final VoidCallback onMarkCorrect;
  final VoidCallback onMarkWrong;
  final String feedback; // none | correct | wrong
  final bool isLoading;

  static const _colorRetry = Color(0xFF4F7CFF);
  static const _colorQuestion = Color(0xFFF5A623);
  static const _colorWrong = Color(0xFFE74C3C);
  static const _colorCorrect = Color(0xFF00B894);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧 4 个竖向按钮
              _buildButtonColumn(),
              const VerticalDivider(
                  width: 1, color: Color(0xFFE5E5E5)),
              const SizedBox(width: 12),
              // 右侧内容
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonColumn() {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          _actionButton(
            label: '重答',
            color: _colorRetry,
            icon: Icons.refresh,
            onTap: onRetry,
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: '疑问',
            color: _colorQuestion,
            icon: Icons.help_outline,
            onTap: onAskDetailed,
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: '错误',
            color: _colorWrong,
            icon: Icons.close,
            selected: feedback == 'wrong',
            onTap: onMarkWrong,
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: '正确',
            color: _colorCorrect,
            icon: Icons.check,
            selected: feedback == 'correct',
            onTap: onMarkCorrect,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.4),
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? Colors.white : color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 题目内容
        Text(
          '题目 ${question.id > 0 ? '#${question.id} ' : ''}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF888888),
              ),
        ),
        const SizedBox(height: 4),
        LatexRenderer(text: question.content),
        const SizedBox(height: 8),
        // 知识点标签
        if (question.knowledgePoints.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: question.knowledgePoints
                .map((kp) => Chip(
                      label: Text(kp),
                      labelStyle:
                          const TextStyle(fontSize: 11, color: Colors.white),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: const Color(0xFF4F7CFF),
                    ))
                .toList(),
          ),
        const Divider(height: 16),
        // 答案
        const Text(
          '答案',
          style: TextStyle(
              fontSize: 12,
              color: Color(0xFF00B894),
              fontWeight: FontWeight.w600),
        ),
        LatexRenderer(text: question.answer),
        const SizedBox(height: 8),
        // 解答过程
        const Text(
          '解答过程',
          style: TextStyle(
              fontSize: 12,
              color: Color(0xFF4F7CFF),
              fontWeight: FontWeight.w600),
        ),
        LatexRenderer(text: question.solution),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 4),
        Text(
          '由 $modelName 提供  ·  置信度 ${(question.confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
        ),
      ],
    );
  }
}
