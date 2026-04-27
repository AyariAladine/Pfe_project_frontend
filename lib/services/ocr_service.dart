import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'token_service.dart';
import '../core/constants/api_constants.dart';

class OcrService {
  TextRecognizer? _textRecognizer;
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  OcrService() {
    // Only initialize ML Kit on non-web platforms
    if (!kIsWeb) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  /// OCR is now available on all platforms (web uses backend API)
  bool get isAvailable => true;

  /// Pick image from camera and extract identity number
  /// Always uses backend API to scan and save CIN number
  Future<String?> scanIdentityCard({bool fromCamera = true}) async {
    final scanData = await scanIdentityCardData(
      side: 'front',
      fromCamera: fromCamera,
    );
    final extractedFields =
        scanData?['extractedFields'] as Map<String, dynamic>? ?? const {};
    final identityNumber = extractedFields['identityNumber']?.toString();
    if (identityNumber != null && identityNumber.isNotEmpty) {
      return identityNumber;
    }

    return _findIdentityNumber(
      scanData?['rawText']?.toString() ?? '',
    );
  }

  /// Pick an ID card image and return a structured OCR payload.
  Future<Map<String, dynamic>?> scanIdentityCardData({
    required String side,
    bool fromCamera = true,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 100,
      );

      if (image == null) return null;

      return await _scanWithBackend(image, side: side);
    } catch (e) {
      debugPrint('Error scanning identity card: $e');
      return null;
    }
  }

  /// Scan image using backend OCR API (for web)
  Future<Map<String, dynamic>?> _scanWithBackend(
    XFile image, {
    required String side,
  }) async {
    try {
      // Get user ID for the endpoint
      final userId = await TokenService.getUserId();
      if (userId == null) {
        debugPrint('User not logged in');
        return null;
      }

      final Uint8List bytes = await image.readAsBytes();
      final String fileName = image.name.isNotEmpty ? image.name : 'image.jpg';

      debugPrint('Uploading image to ${ApiConstants.scanIdCard(userId)}');

      // Endpoint: /users/{userId}/scan-id-card
      final response = await _apiService.uploadFile(
        ApiConstants.scanIdCard(userId),
        fileBytes: bytes,
        fileName: fileName,
        fieldName: 'image',
        fields: {'side': side},
        requiresAuth: true,
      );

      debugPrint('OCR Response: $response');

      return _buildIdentityCardPayload(
        side: side,
        imageName: fileName,
        response: response,
      );
    } catch (e) {
      debugPrint('Error with backend OCR: $e');
      return null;
    }
  }

  Map<String, dynamic> _buildIdentityCardPayload({
    required String side,
    required String imageName,
    required Map<String, dynamic> response,
  }) {
    final extractedFields = _extractNormalizedFields(response);
    final rawText = _extractRawText(response);
    final parsedFromText = _extractTunisianCinFields(
      rawText ?? '',
      side: side,
    );

    for (final entry in parsedFromText.entries) {
      final value = entry.value;
      if (value == null || value.toString().trim().isEmpty) continue;
      extractedFields.putIfAbsent(entry.key, () => value);
    }

    if (!extractedFields.containsKey('identityNumber')) {
      final fallbackCin = _findIdentityNumber(rawText ?? '');
      if (fallbackCin != null && fallbackCin.isNotEmpty) {
        extractedFields['identityNumber'] = fallbackCin;
      }
    }

    return {
      'side': side,
      'imageName': imageName,
      'rawText': rawText,
      'extractedFields': extractedFields,
      'rawResponse': response,
    };
  }

  Map<String, dynamic> _extractNormalizedFields(Map<String, dynamic> response) {
    final normalized = <String, dynamic>{};

    void mergeFields(Map<String, dynamic> source) {
      final mapped = <String, dynamic>{
        'identityNumber': _firstValue(source, const [
          'identityNumber',
          'identitynumber',
          'cinNumber',
          'idCardNumber',
          'cin',
          'cardNumber',
        ]),
        'fullName': _firstValue(source, const ['fullName', 'name']),
        'firstName': _firstValue(source, const ['firstName', 'givenName']),
        'lastName': _firstValue(source, const [
          'lastName',
          'surname',
          'familyName',
        ]),
        'dateOfBirth': _firstValue(source, const [
          'dateOfBirth',
          'birthDate',
          'dob',
        ]),
        'placeOfBirth': _firstValue(source, const [
          'placeOfBirth',
          'birthPlace',
        ]),
        'address': _firstValue(source, const [
          'address',
          'residenceAddress',
          'homeAddress',
        ]),
        'gender': _firstValue(source, const ['gender', 'sex']),
        'nationality': _firstValue(source, const ['nationality']),
        'issueDate': _firstValue(source, const [
          'issueDate',
          'dateOfIssue',
          'issuedAt',
        ]),
        'issuePlace': _firstValue(source, const [
          'issuePlace',
          'issuedIn',
          'deliveryPlace',
        ]),
        'expiryDate': _firstValue(source, const [
          'expiryDate',
          'expirationDate',
          'expiresAt',
        ]),
        'issuer': _firstValue(source, const ['issuer', 'issuedBy', 'authority']),
        'lineage': _firstValue(source, const [
          'lineage',
          'fatherName',
          'parentName',
          'bin',
        ]),
        'barcodeNumber': _firstValue(source, const [
          'barcodeNumber',
          'serialNumber',
          'documentNumber',
        ]),
      };

      for (final entry in mapped.entries) {
        final value = entry.value;
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        normalized[entry.key] = text;
      }
    }

    final nestedCandidates = [
      response['fields'],
      response['data'],
      response['result'],
      response['cardData'],
      response['extractedData'],
      response['ocrData'],
      response['front'],
      response['back'],
      response['user'],
    ];

    for (final candidate in nestedCandidates) {
      if (candidate is Map) {
        mergeFields(Map<String, dynamic>.from(candidate));
      }
    }

    mergeFields(response);
    return normalized;
  }

  String? _extractRawText(Map<String, dynamic> response) {
    final rawText = _firstValue(response, const [
      'text',
      'rawText',
      'ocrText',
      'extractedText',
    ]);
    if (rawText != null) return rawText.toString();

    final data = response['data'];
    if (data is Map) {
      final nestedRawText = _firstValue(
        Map<String, dynamic>.from(data),
        const ['text', 'rawText', 'ocrText', 'extractedText'],
      );
      return nestedRawText?.toString();
    }

    return null;
  }

  dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic> _extractTunisianCinFields(
    String rawText, {
    required String side,
  }) {
    final fields = <String, dynamic>{};
    final normalizedText = _normalizeOcrText(rawText);
    if (normalizedText.isEmpty) return fields;

    final identityNumber = _findIdentityNumber(normalizedText);
    if (identityNumber != null) {
      fields['identityNumber'] = identityNumber;
    }

    if (side == 'front') {
      _putIfFound(fields, 'lastName', _extractLabeledValue(normalizedText, const [
        'اللقب',
        'nom',
      ]));
      _putIfFound(fields, 'firstName', _extractLabeledValue(normalizedText, const [
        'الاسم',
        'prenom',
        'prénom',
      ]));
      _putIfFound(fields, 'dateOfBirth', _extractLabeledValue(normalizedText, const [
        'تاريخ الولادة',
        'date de naissance',
      ]));
      _putIfFound(fields, 'placeOfBirth', _extractLabeledValue(normalizedText, const [
        'مكان الولادة',
        'مكانها',
        'lieu de naissance',
      ]));
      _putIfFound(fields, 'lineage', _extractLineage(normalizedText));

      final firstName = fields['firstName']?.toString();
      final lastName = fields['lastName']?.toString();
      if (firstName != null && lastName != null) {
        fields.putIfAbsent('fullName', () => '$firstName $lastName');
      }
    } else {
      _putIfFound(fields, 'address', _extractBackAddress(normalizedText));
      _putIfFound(fields, 'issueDate', _extractIssueDate(normalizedText));
      _putIfFound(fields, 'issuePlace', _extractIssuePlace(normalizedText));
      _putIfFound(fields, 'barcodeNumber', _extractBackBarcodeNumber(normalizedText));
    }

    return fields;
  }

  String _normalizeOcrText(String text) {
    final westernDigits = text
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');

    return westernDigits
        .replaceAll(RegExp(r'\r'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();
  }

  String? _extractLabeledValue(String text, List<String> labels) {
    for (final label in labels) {
      final pattern = RegExp(
        '${RegExp.escape(label)}\\s*[:：-]?\\s*([^\\n]+)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _extractLineage(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();
    for (final line in lines) {
      if ((line.startsWith('بن ') || line.startsWith('ابن ')) && line.length > 4) {
        return line;
      }
    }
    return null;
  }

  String? _extractBackAddress(String text) {
    final direct = _extractLabeledValue(text, const [
      'العنوان',
      'adresse',
    ]);
    if (direct != null) return direct;

    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    final startIndex = lines.indexWhere(
      (line) => line.contains('العنوان') || line.toLowerCase().contains('adresse'),
    );
    if (startIndex >= 0) {
      final addressLines = <String>[];
      for (var index = startIndex + 1; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('في ') || line.toLowerCase().contains('delivre')) {
          break;
        }
        addressLines.add(line);
      }
      if (addressLines.isNotEmpty) {
        return addressLines.join(', ');
      }
    }

    return null;
  }

  String? _extractIssueDate(String text) {
    final direct = _extractLabeledValue(text, const [
      'حررت في',
      'بتونس في',
      'delivrée le',
      'delivree le',
    ]);
    if (direct != null) return direct;

    final dateMatch = RegExp(
      r'(\d{1,2}\s+[\p{L}A-Za-z]+\s+\d{4})',
      unicode: true,
      caseSensitive: false,
    ).firstMatch(text);
    return dateMatch?.group(1)?.trim();
  }

  String? _extractIssuePlace(String text) {
    final match = RegExp(
      r'(?:بتونس|حررت\s+ب|صادرة\s+ب|delivree\s+a|delivree\s+à)\s+([^\n\d]+)',
      unicode: true,
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1)?.trim();
  }

  String? _extractBackBarcodeNumber(String text) {
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    for (final line in lines) {
      final compact = line.replaceAll(' ', '');
      if (RegExp(r'^\d{8,}$').hasMatch(compact)) {
        return compact;
      }
    }
    return null;
  }

  void _putIfFound(Map<String, dynamic> target, String key, String? value) {
    if (value == null || value.trim().isEmpty) return;
    target[key] = value.trim();
  }

  /// Extract identity number from an image file (mobile only)
  Future<String?> extractIdentityNumber(File imageFile) async {
    if (_textRecognizer == null) return null;

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(
        inputImage,
      );

      // Find potential identity numbers in the recognized text
      final identityNumber = _findIdentityNumber(recognizedText.text);
      return identityNumber;
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return null;
    }
  }

  /// Find identity number pattern in text
  /// This looks for common Tunisian CIN patterns (8 digits)
  String? _findIdentityNumber(String text) {
    // Remove spaces and newlines for easier parsing
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ');

    // Pattern for Tunisian CIN: 8 consecutive digits
    final RegExp cinPattern = RegExp(r'\b(\d{8})\b');
    final match = cinPattern.firstMatch(cleanText);

    if (match != null) {
      return match.group(1);
    }

    // Try to find any sequence of 8 digits even if not word-bounded
    final RegExp relaxedPattern = RegExp(r'(\d{8})');
    final relaxedMatch = relaxedPattern.firstMatch(cleanText);

    if (relaxedMatch != null) {
      return relaxedMatch.group(1);
    }

    // Look for numbers with spaces between them (e.g., "12 34 56 78")
    final RegExp spacedPattern = RegExp(r'(\d{2}\s?\d{2}\s?\d{2}\s?\d{2})');
    final spacedMatch = spacedPattern.firstMatch(cleanText);

    if (spacedMatch != null) {
      return spacedMatch.group(1)?.replaceAll(RegExp(r'\s'), '');
    }

    return null;
  }

  /// Get all recognized text from image (useful for debugging)
  Future<String> getFullText(File imageFile) async {
    if (_textRecognizer == null) return 'OCR not available on web';

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(
        inputImage,
      );
      return recognizedText.text;
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Extract text from image path (works on both web and mobile)
  Future<String?> extractTextFromImage(String imagePath) async {
    if (kIsWeb) {
      // On web, we can't use ML Kit - return null and let user enter manually
      return null;
    }

    if (_textRecognizer == null) return null;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(
        inputImage,
      );
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error extracting text from image: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
