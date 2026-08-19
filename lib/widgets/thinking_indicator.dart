/// 思考中指示器 - 思谛 STDeel
///
/// 液态玻璃胶囊样式：
/// 流式接收 reasoning_content 时显示"AI 思考中..."动画；
/// 切换到 content 阶段时显示"AI 回答中..."。
/// 模型 Failover 切换时显示切换提示。
library;

import 'package:flutter/material.dart';

import 'glass.dart';

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({
    super.key,
    required this.isAnswering,
    this.modelName,
    this.notice,
  });

  /// true=回答中；false=思考中
  final bool isAnswering;
  final String? modelName;
  final String? notice;

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
    final color = isAnswering ? G.mint : G.accent;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: 18,
      fillColor: color.withOpacity(0.08),
      borderColor: color.withOpacity(0.3),
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 波纹动画
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return SizedBox(
                    width: 26,
                    height: 26,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(2, (i) {
                          final t =
                              (_controller.value + i * 0.5) % 1.0;
                          return Container(
                            width: 26 * t,
                            height: 26 * t,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withOpacity((1 - t) * 0.6),
                                width: 1.5,
                              ),
                            ),
                          );
                        }),
                        Icon(
                          isAnswering
                              ? Icons.chat_bubble_rounded
                              : Icons.psychology_rounded,
                          color: color,
                          size: 18,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAnswering
                      ? 'AI 回答中${_modelSuffix}…'
                      : 'AI 思考中${_modelSuffix}…',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const PulsingDot(size: 7),
            ],
          ),
          if (widget.notice != null && widget.notice!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: G.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: G.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 14, color: G.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.notice!,
                      style: const TextStyle(fontSize: 12, color: G.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _modelSuffix =>
      widget.modelName == null || widget.modelName!.isEmpty
          ? ''
          : ' · ${widget.modelName}';
}
