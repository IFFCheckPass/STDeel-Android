/// 思考中指示器 - 思谛 STDeel
///
/// 流式接收 reasoning_content 时显示"AI 思考中..."动画；
/// 切换到 content 阶段时显示"AI 回答中..."。
library;

import 'package:flutter/material.dart';

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({
    super.key,
    required this.isAnswering,
    this.modelName,
  });

  /// true=回答中；false=思考中
  final bool isAnswering;
  final String? modelName;

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAnswering = widget.isAnswering;
    final color =
        isAnswering ? const Color(0xFF00B894) : const Color(0xFF4F7CFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _controller,
            child: Icon(
              isAnswering ? Icons.chat_bubble : Icons.psychology,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isAnswering
                ? 'AI 回答中${widget.modelName == null ? '' : ' · ${widget.modelName}'}...'
                : 'AI 思考中${widget.modelName == null ? '' : ' · ${widget.modelName}'}...',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            height: 4,
            child: LinearProgressIndicator(
              backgroundColor: color.withOpacity(0.2),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
