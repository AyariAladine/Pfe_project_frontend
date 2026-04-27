// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

html.VideoElement? _video;
html.MediaStream? _stream;

/// Start the front-facing camera and register an HtmlElementView.
/// Returns the viewType id to use with HtmlElementView.
Future<String> startCamera() async {
  _stream = await html.window.navigator.mediaDevices!.getUserMedia({
    'video': {'facingMode': 'user', 'width': 640, 'height': 480},
    'audio': false,
  });

  _video = html.VideoElement()
    ..autoplay = true
    ..setAttribute('playsinline', 'true')
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover'
    ..style.transform = 'scaleX(-1)'
    ..srcObject = _stream;

  await _video!.play();

  final viewId = 'face-camera-${DateTime.now().millisecondsSinceEpoch}';
  ui_web.platformViewRegistry
      .registerViewFactory(viewId, (int _) => _video!);

  return viewId;
}

/// Stop camera and release resources.
void stopCamera() {
  _stream?.getTracks().forEach((track) => track.stop());
  _video?.pause();
  _video?.srcObject = null;
  _video = null;
  _stream = null;
}

/// Capture the current video frame as JPEG bytes.
Future<Uint8List?> captureFrame() async {
  if (_video == null) return null;

  final canvas = html.CanvasElement(
    width: _video!.videoWidth,
    height: _video!.videoHeight,
  );
  // Mirror horizontally to match the preview
  final ctx = canvas.context2D;
  ctx.translate(canvas.width!.toDouble(), 0);
  ctx.scale(-1, 1);
  ctx.drawImage(_video!, 0, 0);

  final blob = await canvas.toBlob('image/jpeg', 0.85);
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();
  reader.onLoadEnd.listen((_) {
    final result = reader.result as List<int>;
    completer.complete(Uint8List.fromList(result));
  });
  reader.readAsArrayBuffer(blob);
  return completer.future;
}
