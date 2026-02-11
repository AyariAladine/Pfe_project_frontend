import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/token_service.dart';

/// Network image widget that includes auth token in headers
/// This is needed for Flutter Web to handle CORS and authenticated image requests
class NetworkImageWithAuth extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function()? placeholder;
  final Widget Function()? errorBuilder;
  final double? width;
  final double? height;

  const NetworkImageWithAuth({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
  });

  @override
  State<NetworkImageWithAuth> createState() => _NetworkImageWithAuthState();
}

class _NetworkImageWithAuthState extends State<NetworkImageWithAuth> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(NetworkImageWithAuth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageBytes = null;
    });

    try {
      final token = await TokenService.getAccessToken();
      final response = await http.get(
        Uri.parse(widget.imageUrl),
        headers: token != null && token.isNotEmpty
            ? {'Authorization': 'Bearer $token'}
            : null,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder?.call() ??
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    if (_hasError || _imageBytes == null) {
      return widget.errorBuilder?.call() ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.grey[600]),
          );
    }

    return Image.memory(
      _imageBytes!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
    );
  }
}
