/// 拍照/上传页 - 思谛 STDeel
///
/// 使用 image_picker 完成拍照或从相册选择，
/// 选定后把图片路径 pop 回上层。
library;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
        Navigator.of(context).pop(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取图失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
            Icon(
              Icons.add_a_photo,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              '拍照或选择图片，AI 将直接解题',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888)),
            ),
            const SizedBox(height: 32),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              FilledButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('从相册选择'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF6C7686),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
