import 'dart:typed_data';

/// Stub for non-web platforms. These are never called on mobile.
Future<String> startCamera() async =>
    throw UnsupportedError('Web camera not available on this platform');

void stopCamera() {}

Future<Uint8List?> captureFrame() async => null;
