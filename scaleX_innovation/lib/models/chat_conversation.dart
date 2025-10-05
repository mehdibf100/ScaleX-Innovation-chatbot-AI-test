// lib/models/chat_conversation.dart
import 'chat_message.dart';

class ChatConversation {
  final String id;
  String title;
  String language; // ex: 'en', 'fr', 'ar'
  final DateTime createdAt;
  List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.title,
    this.language = 'en',
    DateTime? createdAt,
    List<ChatMessage>? messages,
  })  : createdAt = createdAt ?? DateTime.now(),
        messages = messages ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'language': language,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toMap()).toList(),
  };

  factory ChatConversation.fromMap(Map m) {
    final msgs = <ChatMessage>[];
    if (m['messages'] is List) {
      for (var e in m['messages']) {
        msgs.add(ChatMessage.fromMap(Map<String, dynamic>.from(e)));
      }
    }
    return ChatConversation(
      id: m['id'] as String,
      title: m['title'] as String? ?? 'Conversation',
      language: m['language'] as String? ?? 'en',
      createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      messages: msgs,
    );
  }
}