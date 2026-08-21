/// 拍照/上传页 - 思谛 STDeel
///
/// 使用 image_picker 完成拍照或从相册选择，
/// 选定后进入裁切/旋转编辑页，编辑完成把最终图片路径 pop 回上层。
library;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/glass.dart';
import 'image_edit_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.initialCamera = true});

  final bool initialCamera;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        // 压入编辑页（保留本页），编辑完成 pop 回传最终图片路径
        final edited = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => ImageEditScreen(imagePath: file.path)),
        );
        if (mounted && edited != null) {
          // 编辑成功：把最终路径回传给首页，由首页跳转 AnswerScreen 触发解题
          Navigator.of(context).pop(edited);
        } else if (mounted) {
          // 用户取消编辑：停留在选图页，可重新选择
          setState(() => _busy = false);
        }
      } else if (mounted) {
        // 用户取消选择
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, '取图失败: $e', error: true);
        setState(() => _busy = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pick(
            ImageSource.camera,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('拍照 / 选图')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(32),
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
                      Icons.add_a_photo_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '拍照或选择图片，AI 将直接解题',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: G.textSecondary, letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_busy)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('正在打开相机…', style: TextStyle(color: G.textSecondary)),
                  ],
                ),
              )
            else ...[
              GlassPrimaryButton(
                icon: Icons.camera_alt_rounded,
                label: '拍照',
                onPressed: () => _pick(ImageSource.camera),
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
                onPressed: () => _pick(ImageSource.gallery),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
