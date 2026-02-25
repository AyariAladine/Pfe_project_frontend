import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/chat_message.dart';

const String _kChatbotBaseUrl = ApiConstants.chatbotBaseUrl;

class ChatbotServiceException implements Exception {
  final String message;
  final String? reason;
  ChatbotServiceException(this.message, {this.reason});
  @override
  String toString() => message;
}

class ChatbotAskResult {
  final String answer;
  final String language;
  final String geminiModel;
  final List<LegalSource> sources;
  final int processingTimeMs;

  ChatbotAskResult({
    required this.answer,
    required this.language,
    required this.geminiModel,
    required this.sources,
    required this.processingTimeMs,
  });
}

class ChatbotService {
  final http.Client _client;

  ChatbotService({http.Client? client}) : _client = client ?? http.Client();

  /// Ask a legal question. Returns the AI answer and sources.
  Future<ChatbotAskResult> ask(
    String question, {
    int topK = 5,
    int? lawNum,
  }) async {
    final url = '$_kChatbotBaseUrl/ask';
    debugPrint('[ChatbotService] POST $url');
    try {
      final body = <String, dynamic>{
        'question': question,
        'topK': topK,
        if (lawNum != null) 'lawNum': lawNum,
      };
      debugPrint('[ChatbotService] Request body: ${jsonEncode(body)}');
      debugPrint('[ChatbotService] Request headers: {Content-Type: application/json}');
      debugPrint('[ChatbotService] Environment: kIsWeb=$kIsWeb');
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('[ChatbotService] Response status: ${response.statusCode}');
      debugPrint('[ChatbotService] Response body: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final reason = data['reason']?.toString() ?? 'unknown';
        final hint = data['hint']?.toString() ?? '';
        final msg = data['error']?.toString() ?? 'Server error ${response.statusCode}';
        debugPrint('[ChatbotService] ERROR $msg | reason=$reason | hint=$hint');
        throw ChatbotServiceException(
          msg,
          reason: '$reason${hint.isNotEmpty ? ' — $hint' : ''}',
        );
      }

      final rawSources = data['sources'] as List<dynamic>? ?? [];
      debugPrint('[ChatbotService] OK — ${rawSources.length} sources, '
          'lang=${data['language']}, model=${data['geminiModel']}');
      return ChatbotAskResult(
        answer: data['answer']?.toString() ?? '',
        language: data['language']?.toString() ?? 'english',
        geminiModel: data['geminiModel']?.toString() ?? '',
        sources: rawSources
            .map((s) => LegalSource.fromJson(s as Map<String, dynamic>))
            .toList(),
        processingTimeMs: data['processingTimeMs'] as int? ?? 0,
      );
    } on ChatbotServiceException {
      rethrow;
    } catch (e, st) {
      debugPrint('[ChatbotService] EXCEPTION during ask: $e');
      debugPrint('[ChatbotService] Stack: $st');
      debugPrint('[ChatbotService] Failed request details:');
      debugPrint('  URL: $url');
      debugPrint('  Body: ${jsonEncode({
        'question': question,
        'topK': topK,
        if (lawNum != null) 'lawNum': lawNum,
      })}');
      debugPrint('  Headers: {Content-Type: application/json}');
      debugPrint('  Environment: kIsWeb=$kIsWeb');
      throw ChatbotServiceException(
        'Connection error: ${e.toString()}',
        reason: 'network',
      );
    }
  }

  /// Quick health check to verify the service is reachable.
  Future<bool> isHealthy() async {
    final url = '$_kChatbotBaseUrl/health';
    debugPrint('[ChatbotService] GET $url');
    debugPrint('[ChatbotService] Environment: kIsWeb=$kIsWeb');
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      debugPrint('[ChatbotService] Health status: ${response.statusCode}');
      debugPrint('[ChatbotService] Health response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e, st) {
      debugPrint('[ChatbotService] Health check FAILED: $e');
      debugPrint('[ChatbotService] Stack: $st');
      debugPrint('[ChatbotService] Failed health check details:');
      debugPrint('  URL: $url');
      debugPrint('  Environment: kIsWeb=$kIsWeb');
      return false;
    }
  }
}
