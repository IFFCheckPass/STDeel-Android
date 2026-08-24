/// LaTeX 渲染封装 - 思谛 STDeel
///
/// 包一层 flutter_tex，把 markdown 行内/块级公式分别渲染。
/// 如果 flutter_tex 在某些设备上未初始化，给出降级文本视图。
library;

import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class LatexRenderer extends StatelessWidget {
  const LatexRenderer({
    super.key,
    required this.text,
    this.isBlock = true,
  });

  /// 包含 LaTeX（$...$ 或 $$...$$）的原文
  final String text;
  final bool isBlock;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final widget = isBlock
          ? TeXView(
              child: TeXViewDocument(_wrapMarkdown(text)),
              style: TeXViewStyle(
                padding: const TeXViewPadding.all(8),
                textAlign: TeXViewTextAlign.left,
              ),
            )
          : TeXView(
              child: TeXViewDocument(text),
              style: TeXViewStyle(
                padding: const TeXViewPadding.all(0),
              ),
            );

      return widget;
    } catch (_) {
      // 降级：纯文本
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
  }

  /// 把 markdown 中的 ``` ``` 代码块和 $...$ / $$...$$ 转给 TeXView。
  /// 数学块（$...$ / $$...$$）保持原样交给 KaTeX 渲染；对加粗/行内代码等
  /// 常见 markdown 做轻量到 LaTeX 的转换（KaTeX 支持 \textbf/\\texttt）。
  String _wrapMarkdown(String source) {
    if (source.isEmpty) return source;
    var out = source;
    // 加粗 **text** → \textbf{text}
    out = out.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (m) => r'\textbf{' + m[1]!.trim() + '}',
    );
    // 反引号行内代码 `code` → \texttt{code}
    out = out.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) => r'\texttt{' + m[1]! + '}',
    );
    return out;
  }
}
