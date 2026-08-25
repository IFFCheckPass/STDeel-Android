/// 题目/答案/解答文本渲染封装 - 思谛 STDeel
///
/// 统一使用可滚动、可选择的 [SelectableText] 渲染，确保答案在解题页、
/// 历史页都**必然可见**。历史上曾使用 flutter_tex 的 TeXView（WebView）
/// 渲染 LaTeX，但在受限布局（Column / IntrinsicHeight / 可滚动容器）中
/// 经常渲染为空白，导致"解题页看不到答案、只能去历史记录看"。
/// 为保证阅读体验与历史页一致（历史页用 SelectableText 一直正常），
/// 这里改为纯文本渲染，公式以原文形式呈现。
library;

import 'package:flutter/material.dart';

class LatexRenderer extends StatelessWidget {
  const LatexRenderer({
    super.key,
    required this.text,
    this.isBlock = true,
  });

  /// 题目 / 答案 / 解答原文
  final String text;
  final bool isBlock;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return SelectableText(
      text,
      style: TextStyle(height: 1.6, fontSize: isBlock ? 14 : 13),
    );
  }
}
