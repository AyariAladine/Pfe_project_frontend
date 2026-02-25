/// Represents a single message in the AI assistant chat.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<LegalSource> sources;
  final String? language;
  final String? geminiModel;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources = const [],
    this.language,
    this.geminiModel,
    this.isError = false,
  });

  ChatMessage copyWith({String? text, bool? isError}) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      sources: sources,
      language: language,
      geminiModel: geminiModel,
      isError: isError ?? this.isError,
    );
  }
}

/// A legal article source returned by the RAG pipeline.
class LegalSource {
  final String chunkId;
  final int lawNum;
  final String articleNum;
  final String text;
  final double score;
  final int? page;

  LegalSource({
    required this.chunkId,
    required this.lawNum,
    required this.articleNum,
    required this.text,
    required this.score,
    this.page,
  });

  factory LegalSource.fromJson(Map<String, dynamic> json) {
    return LegalSource(
      chunkId: json['chunk_id']?.toString() ?? '',
      lawNum: json['law_num'] as int? ?? 0,
      articleNum: json['article_num']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      page: json['page'] as int?,
    );
  }
}
