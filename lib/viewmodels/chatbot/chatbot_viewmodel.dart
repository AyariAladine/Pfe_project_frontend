import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_message.dart';
import '../../services/chatbot_service.dart';

class ChatbotViewModel extends ChangeNotifier {
  final ChatbotService _service;
  static const String _storageKey = 'chatbot_messages';

  ChatbotViewModel({ChatbotService? service})
      : _service = service ?? ChatbotService() {
    _loadMessages();
  }

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

  /// Load persisted messages from local storage.
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _messages.addAll(
          list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatbotViewModel] Failed to load messages: $e');
    }
  }

  /// Persist messages to local storage.
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_messages.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      debugPrint('[ChatbotViewModel] Failed to save messages: $e');
    }
  }

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
      _saveMessages();
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
    _saveMessages();
  }
}
