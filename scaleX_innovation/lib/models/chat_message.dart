// lib/models/chat_message.dart
class ChatMessage {
  final String role;
  String content;
  final DateTime createdAt;
  bool isDraft;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.isDraft = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'role': role,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'isDraft': isDraft,
  };

  factory ChatMessage.fromMap(Map m) => ChatMessage(
    role: m['role'] as String,
    content: m['content'] as String,
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    isDraft: m['isDraft'] == true,
  );
}
