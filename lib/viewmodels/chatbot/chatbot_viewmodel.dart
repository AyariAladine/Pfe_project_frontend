import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/chatbot_service.dart';

class ChatbotViewModel extends ChangeNotifier {
  final ChatbotService _service;

  ChatbotViewModel({ChatbotService? service})
      : _service = service ?? ChatbotService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _serviceAvailable = true;
  String? _errorBanner; // non-fatal banner message (e.g. quota exceeded hint)

  // ── Public getters ─────────────────────────────────────────────────────────

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get serviceAvailable => _serviceAvailable;
  String? get errorBanner => _errorBanner;
  bool get hasMessages => _messages.isNotEmpty;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Send a user message and get the AI response.
  Future<void> sendMessage(String question) async {
    debugPrint('[DEBUG] sendMessage called with: "$question"');
    if (question.trim().isEmpty || _isLoading) return;

    _errorBanner = null;

    // Add user bubble immediately
    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: question.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    debugPrint('[ChatbotViewModel] Sending question: "$question"');
    try {
      debugPrint('[DEBUG] Calling _service.ask');
      final result = await _service.ask(question.trim());
      debugPrint('[ChatbotViewModel] Answer received (${result.processingTimeMs}ms)');

      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: result.answer,
        isUser: false,
        timestamp: DateTime.now(),
        sources: result.sources,
        language: result.language,
        geminiModel: result.geminiModel,
      ));
      debugPrint('[DEBUG] Answer message added to _messages');
    } on ChatbotServiceException catch (e) {
      debugPrint('[ChatbotViewModel] ChatbotServiceException: ${e.message} | reason=${e.reason}');
      final isQuota = e.reason?.contains('quota') ?? false;
      final isNetwork = e.reason?.contains('network') ?? false;

      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: isNetwork
            ? 'Unable to reach the AI service. Please check your connection and try again.'
            : isQuota
                ? 'The AI service has temporarily exceeded its quota. Please try again in a few minutes.'
                : 'An error occurred: ${e.message}',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
      debugPrint('[DEBUG] Error message added to _messages');
    } catch (e, st) {
      debugPrint('[ChatbotViewModel] Unexpected error: $e');
      debugPrint('[ChatbotViewModel] Stack: $st');
      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: 'Unexpected error: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
      debugPrint('[DEBUG] Unexpected error message added to _messages');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[DEBUG] sendMessage finished, _isLoading set to false');
    }
  }

  /// Check connectivity to the RAG service.
  Future<void> checkHealth() async {
    _serviceAvailable = await _service.isHealthy();
    notifyListeners();
  }

  /// Clear all conversation history.
  void clearHistory() {
    _messages.clear();
    _errorBanner = null;
    notifyListeners();
  }
}
