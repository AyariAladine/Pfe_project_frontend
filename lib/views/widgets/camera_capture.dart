import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';

// Conditional web import
import 'web_camera_stub.dart' if (dart.library.html) 'web_camera_impl.dart'
    as web_camera;

/// Opens the front camera and returns captured JPEG bytes, or null if cancelled.
/// On mobile: uses image_picker camera.
/// On web desktop: opens a live camera dialog using getUserMedia.
Future<Uint8List?> captureFromCamera(BuildContext context) async {
  if (kIsWeb) {
    return _captureWebCamera(context);
  } else {
    return _captureMobileCamera();
  }
}

Future<Uint8List?> _captureMobileCamera() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.front,
    maxWidth: 640,
    maxHeight: 640,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return picked.readAsBytes();
}

Future<Uint8List?> _captureWebCamera(BuildContext context) async {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WebCameraDialog(),
  );
}

class _WebCameraDialog extends StatefulWidget {
  const _WebCameraDialog();

  @override
  State<_WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<_WebCameraDialog> {
  String? _viewId;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final id = await web_camera.startCamera();
      if (!mounted) return;
      setState(() {
        _viewId = id;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    web_camera.stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 550),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Camera',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Video preview
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Camera not available:\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  : !_ready
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: HtmlElementView(viewType: _viewId!),
                        ),
            ),

            // Capture button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.black87,
              child: Center(
                child: GestureDetector(
                  onTap: _ready ? _capture : null,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _ready
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                    child: const Icon(Icons.camera, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capture() async {
    try {
      final bytes = await web_camera.captureFrame();
      if (bytes != null && mounted) {
        Navigator.pop(context, bytes);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }
}
