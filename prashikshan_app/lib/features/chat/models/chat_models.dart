class ChatSession {
  final String sessionId;
  final String lastMessage;
  final DateTime createdAt;

  ChatSession({
    required this.sessionId,
    required this.lastMessage,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'],
      lastMessage: json['last_message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({
    required this.role,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}
