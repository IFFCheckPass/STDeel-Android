/// 图片编辑页（裁切 + 旋转）- 思谛 STDeel
///
/// 拍照/选图后进入本页：
///   - 双指缩放 / 拖动图片调整取景
///   - 中心裁切框（可选比例：原图 / 3:4 / 1:1 / 4:3）
///   - 左右旋转 90°
///   - 确认后在 isolate 中完成解码→旋转→裁切→JPEG 编码
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show MatrixUtils;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../widgets/glass.dart';

/// Aspect 选项
class _AspectOption {
  const _AspectOption(this.label, this.ratio);
  final String label;

  /// null = 原图比例
  final double? ratio;
}

const _aspectOptions = [
  _AspectOption('原图', null),
  _AspectOption('3:4', 3 / 4),
  _AspectOption('1:1', 1.0),
  _AspectOption('4:3', 4 / 3),
];

class ImageEditScreen extends StatefulWidget {
  const ImageEditScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends State<ImageEditScreen> {
  ui.Size _imageSize = ui.Size.zero;
  bool _loading = true;
  bool _processing = false;
  String? _error;

  final TransformationController _controller = TransformationController();
  int _quarterTurns = 0;
  int _aspectIndex = 0;

  // 视口尺寸（LayoutBuilder 捕获）
  Size _viewportSize = Size.zero;

  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = await compute(_decodeSize, bytes);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _imageSize = decoded;
        _loading = false;
      });
      _scheduleFit();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '图片加载失败：$e';
        _loading = false;
      });
    }
  }

  /// 旋转后的图片尺寸（逻辑坐标系）
  Size get _rotatedSize {
    final w = _imageSize.width;
    final h = _imageSize.height;
    return _quarterTurns % 2 == 0 ? Size(w, h) : Size(h, w);
  }

  /// 裁切框（视口坐标，居中）
  Rect _cropRect() {
    if (_viewportSize == Size.zero) return Rect.zero;
    final option = _aspectOptions[_aspectIndex];
    final vw = _viewportSize.width;
    final vh = _viewportSize.height;
    double ratio;
    if (option.ratio == null) {
      final rs = _rotatedSize;
      ratio = rs.aspectRatio == 0 ? 0.75 : rs.aspectRatio;
    } else {
      ratio = option.ratio!;
    }
    var w = vw * 0.86;
    var h = w / ratio;
    if (h > vh * 0.8) {
      h = vh * 0.8;
      w = h * ratio;
    }
    return Rect.fromCenter(
      center: Offset(vw / 2, vh / 2),
      width: w,
      height: h,
    );
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitView());
  }

  /// 重置缩放/平移，使图片 contain 到视口
  void _fitView() {
    if (_viewportSize == Size.zero || _imageSize == ui.Size.zero) return;
    final rs = _rotatedSize;
    if (rs.width == 0 || rs.height == 0) return;
    final scale =
        _viewportSize.width / rs.width < _viewportSize.height / rs.height
            ? _viewportSize.width / rs.width
            : _viewportSize.height / rs.height;
    // 稍微小一点，四周留白
    final s = scale * 0.98;
    final dx = (_viewportSize.width - rs.width * s) / 2;
    final dy = (_viewportSize.height - rs.height * s) / 2;
    _controller.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(s);
    setState(() {});
  }

  void _rotate({required bool clockwise}) {
    setState(() {
      _quarterTurns =
          ((_quarterTurns + (clockwise ? 1 : 3)) % 4);
    });
    _scheduleFit();
  }

  Future<void> _confirm() async {
    if (_processing || _bytes == null) return;
    setState(() => _processing = true);

    try {
      final cropViewport = _cropRect();
      // 视口坐标 → 子组件（旋转后图片）坐标
      final matrix = _controller.value;
      final inverted = Matrix4.inverted(matrix);
      var childRect = MatrixUtils.transformRect(inverted, cropViewport);

      // 与图片 bounds 求交集
      final rs = _rotatedSize;
      final bounds = Rect.fromLTWH(0, 0, rs.width, rs.height);
      childRect = childRect.intersect(bounds);
      if (childRect.width < 8 || childRect.height < 8) {
        childRect = bounds;
      }

      final crop = (
        bytes: _bytes!,
        quarterTurns: _quarterTurns,
        x: childRect.left.round().clamp(0, rs.width.round() - 1),
        y: childRect.top.round().clamp(0, rs.height.round() - 1),
        w: childRect.width.round().clamp(1, rs.width.round()),
        h: childRect.height.round().clamp(1, rs.height.round()),
      );

      final outBytes = await compute(_cropAndEncode, crop);

      final dir = await getTemporaryDirectory();
      final outFile = File(
        '${dir.path}/stdeel_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await outFile.writeAsBytes(outBytes);

      if (!mounted) return;
      Navigator.of(context).pop(outFile.path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      showGlassSnackBar(context, '裁切失败：$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调整图片'),
        actions: [
          IconButton(
            tooltip: '重置',
            icon: const Icon(Icons.restart_alt),
            onPressed: () {
              setState(() => _quarterTurns = 0);
              _scheduleFit();
            },
          ),
        ],
      ),
      body: _loading || _error != null
          ? _buildPlaceholder()
          : Column(
              children: [
                Expanded(child: _buildViewer()),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildPlaceholder() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: G.coral)),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildViewer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = constraints.biggest;
        return Stack(
          children: [
            // 图片 + 手势
            InteractiveViewer(
              transformationController: _controller,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.2,
              maxScale: 8,
              onInteractionEnd: (_) => setState(() {}),
              child: RotatedBox(
                quarterTurns: _quarterTurns,
                child: Image.memory(
                  _bytes!,
                  gaplessPlayback: true,
                ),
              ),
            ),
            // 裁切框遮罩
            IgnorePointer(
              child: CustomPaint(
                painter: _CropOverlayPainter(rect: _cropRect()),
                size: Size.infinite,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: GlassCard(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        radius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 比例选择
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _aspectOptions.length; i++)
                  _aspectChip(i),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // 左旋
                _roundIconBtn(
                  icon: Icons.rotate_left_rounded,
                  onTap: () => _rotate(clockwise: false),
                ),
                const SizedBox(width: 8),
                // 右旋
                _roundIconBtn(
                  icon: Icons.rotate_right_rounded,
                  onTap: () => _rotate(clockwise: true),
                ),
                const Spacer(),
                // 使用原图
                TextButton(
                  onPressed: () => Navigator.of(context).pop(widget.imagePath),
                  child: const Text('跳过'),
                ),
                const SizedBox(width: 8),
                // 确认
                _processing
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : GlassPrimaryButton(
                        icon: Icons.check_rounded,
                        label: '完成',
                        height: 48,
                        onPressed: _confirm,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _aspectChip(int index) {
    final selected = _aspectIndex == index;
    final option = _aspectOptions[index];
    return GestureDetector(
      onTap: () {
        setState(() => _aspectIndex = index);
        _scheduleFit();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? G.accentDeep.withOpacity(0.4) : G.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? G.accent : G.glassBorder,
          ),
        ),
        child: Text(
          option.label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? G.textPrimary : G.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _roundIconBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: G.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: G.glassBorder),
        ),
        child: Icon(icon, color: G.textPrimary, size: 22),
      ),
    );
  }
}

/// 裁切框绘制：外部暗化 + 边框 + 三分线
class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    if (rect == Rect.zero) return;

    // 暗化裁切框外部
    final overlay = Paint()..color = Colors.black.withOpacity(0.55);
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)));
    final diff = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(diff, overlay);

    // 边框
    final border = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      border,
    );

    // 三分线
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 1; i <= 2; i++) {
      final dx = rect.left + rect.width * i / 3;
      canvas.drawLine(Offset(dx, rect.top), Offset(dx, rect.bottom), grid);
      final dy = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), grid);
    }

    // 四角高光
    final corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const c = 18.0;
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    // 左上
    canvas.drawLine(Offset(r.left, r.top + c), Offset(r.left, r.top), corner);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + c, r.top), corner);
    // 右上
    canvas.drawLine(Offset(r.right - c, r.top), Offset(r.right, r.top), corner);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + c), corner);
    // 左下
    canvas.drawLine(Offset(r.left, r.bottom - c), Offset(r.left, r.bottom), corner);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + c, r.bottom), corner);
    // 右下
    canvas.drawLine(Offset(r.right - c, r.bottom), Offset(r.right, r.bottom), corner);
    canvas.drawLine(Offset(r.right, r.bottom - c), Offset(r.right, r.bottom), corner);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) => old.rect != rect;
}

// ---------- Isolate 任务 ----------

/// 解码获取尺寸（避免阻塞 UI）
ui.Size _decodeSize(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) throw '无法解码图片';
  return ui.Size(image.width.toDouble(), image.height.toDouble());
}

/// 裁切参数（isolate 传递）
typedef _CropArgs = ({
  Uint8List bytes,
  int quarterTurns,
  int x,
  int y,
  int w,
  int h,
});

/// 旋转 → 裁切 → JPEG 编码（isolate 中执行）
Uint8List _cropAndEncode(_CropArgs args) {
  final src = img.decodeImage(args.bytes);
  if (src == null) throw '无法解码图片';

  var rotated = src;
  if (args.quarterTurns > 0) {
    rotated = img.copyRotate(src, angle: args.quarterTurns * 90);
  }

  // clamp 裁切区域
  final x = args.x.clamp(0, rotated.width - 1);
  final y = args.y.clamp(0, rotated.height - 1);
  final w = args.w.clamp(1, rotated.width - x);
  final h = args.h.clamp(1, rotated.height - y);

  final cropped = img.copyCrop(
    rotated,
    x: x,
    y: y,
    width: w,
    height: h,
  );
  final jpg = img.encodeJpg(cropped, quality: 90);
  return Uint8List.fromList(jpg);
}
