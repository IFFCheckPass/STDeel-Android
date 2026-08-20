/// 液态玻璃设计系统 - 思谛 STDeel
///
/// 深空渐变背景 + 漂浮光球 + 磨砂玻璃卡片。
/// 全局通过 [GlassBackground]（app builder）铺底，
/// 各页面使用 [GlassCard] / [GlassSection] 组合界面。
library;

import 'dart:math' as math;

import 'dart:ui';

import 'package:flutter/material.dart';

/// 设计令牌
class G {
  G._();

  // 背景渐变（深空）
  static const Color bgTop = Color(0xFF0F1326);
  static const Color bgMid = Color(0xFF1A2040);
  static const Color bgBottom = Color(0xFF251E4E);

  // 主题色
  static const Color accent = Color(0xFF7C9CFF);
  static const Color accentDeep = Color(0xFF4F7CFF);
  static const Color mint = Color(0xFF00D9A6);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color amber = Color(0xFFFFC24B);

  // 文字
  static const Color textPrimary = Color(0xFFEFF2FF);
  static const Color textSecondary = Color(0xFF9AA3C7);
  static const Color textFaint = Color(0xFF6B7399);

  // 玻璃
  static const Color glassFill = Color(0x14FFFFFF); // 8% 白
  static const Color glassFillStrong = Color(0x24FFFFFF); // 14% 白
  static const Color glassBorder = Color(0x29FFFFFF); // 16% 白
  static const Color glassHighlight = Color(0x40FFFFFF); // 25% 白（高光描边）

  static const double radius = 22;
  static const double blur = 18;

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentDeep, Color(0xFF8A6CFF)],
      );

  static ThemeData theme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentDeep,
        brightness: Brightness.dark,
      ).copyWith(
        primary: accent,
        secondary: mint,
        surface: const Color(0xFF1A2040),
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xE61A2040),
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassFill,
        hintStyle: const TextStyle(color: textFaint),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentDeep,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : textFaint),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accentDeep
                : const Color(0xFF2A3055)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xD90F1326),
        surfaceTintColor: Colors.transparent,
        indicatorColor: accentDeep.withOpacity(0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: states.contains(WidgetState.selected)
                  ? textPrimary
                  : textSecondary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? accent
                  : textSecondary,
            )),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: accentDeep.withOpacity(0.25),
        labelStyle: const TextStyle(fontSize: 11, color: textPrimary),
        side: BorderSide(color: accentDeep.withOpacity(0.5)),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: accent),
      dividerTheme: const DividerThemeData(color: glassBorder),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xF01A2040),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: glassBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF01A2040),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF0141834),
        modalBackgroundColor: Color(0xF0141834),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

/// 全局液态玻璃背景：深空渐变 + 缓慢漂移的光球
class GlassBackground extends StatefulWidget {
  const GlassBackground({super.key, this.child});

  final Widget? child;

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground>
    with TickerProviderStateMixin {
  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_orbCtrl.value);
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [G.bgTop, G.bgMid, G.bgBottom],
              stops: [0, 0.55, 1],
            ),
          ),
          child: Stack(
            children: [
              // 漂浮光球
              Positioned(
                top: -80 + 40 * t,
                right: -60 + 50 * (1 - t),
                child: _orb(220, G.accentDeep.withOpacity(0.35)),
              ),
              Positioned(
                bottom: -60 + 50 * t,
                left: -80 + 40 * (1 - t),
                child: _orb(260, const Color(0xFF8A6CFF).withOpacity(0.25)),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.35 + 30 * t,
                left: -40 + 60 * (1 - t),
                child: _orb(140, G.mint.withOpacity(0.10)),
              ),
              if (widget.child != null) child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      );
}

/// 磨砂玻璃卡片
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = G.radius,
    this.blurSigma = G.blur,
    this.fillColor = G.glassFill,
    this.borderColor = G.glassBorder,
    this.glowColor,
    this.borderRadius,
    this.clipBehavior,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blurSigma;
  final Color fillColor;
  final Color borderColor;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(radius);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: br,
        clipBehavior: clipBehavior ?? Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: br,
              border: Border.all(color: borderColor),
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.6,
                colors: [
                  G.glassHighlight.withOpacity(0.5),
                  G.glassFill.withOpacity(0),
                ],
                stops: const [0, 0.55],
              ),
              boxShadow: glowColor == null
                  ? null
                  : [
                      BoxShadow(
                        color: glowColor!.withOpacity(0.25),
                        blurRadius: 24,
                        spreadRadius: -8,
                      ),
                    ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 分区标题（带细线装饰）
class GlassSectionTitle extends StatelessWidget {
  const GlassSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: G.primaryGradient,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: G.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 渐变主按钮（玻璃质感）
class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.height = 58,
    this.gradient,
    this.borderColor = G.glassHighlight,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Gradient? gradient;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient ?? G.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: G.accentDeep.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: -6,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: borderColor.withOpacity(0.6)),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}

/// 通用反馈 SnackBar
void showGlassSnackBar(
  BuildContext context,
  String message, {
  bool success = false,
  bool error = false,
}) {
  final color = success
      ? G.mint
      : error
          ? G.coral
          : G.accent;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_outline
                  : error
                      ? Icons.error_outline
                      : Icons.info_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(milliseconds: success ? 2000 : 3000),
      ),
    );
}

/// 呼吸光点（思考指示器等使用）
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.color = G.accent, this.size = 8});

  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = 0.6 + 0.6 * Curves.easeInOut.transform(_ctrl.value);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.6),
                  blurRadius: 8 * scale,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 工具函数：随机 id
String glassRandId() =>
    (math.Random().nextInt(0x7FFFFFFF)).toRadixString(36);
