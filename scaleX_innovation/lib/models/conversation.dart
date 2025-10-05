// lib/models/conversation.dart
import 'package:scalex_innovation/models/chat_message.dart';

class Conversation {
  final String id; // local uuid
  int? remoteId; // id côté serveur (int)
  String? remoteSummaryId; // id du summary distant (uuid string)
  String title;
  List<ChatMessage> messages;
  DateTime createdAt;
  DateTime updatedAt;
  String summary;

  Conversation({
    required this.id,
    this.remoteId,
    this.remoteSummaryId,
    required this.title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.summary = '',
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  Map<String, dynamic> toMap() => {
    'id': id,
    'remoteId': remoteId,
    'remoteSummaryId': remoteSummaryId,
    'title': title,
    'messages': messages.map((m) => m.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'summary': summary,
  };

  factory Conversation.fromMap(Map m) => Conversation(
    id: m['id'] as String,
    remoteId: _parseNullableInt(m['remoteId']),
    remoteSummaryId: m['remoteSummaryId'] as String?,
    title: m['title'] as String? ?? 'Conversation',
    messages: (m['messages'] as List? ?? [])
        .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
    summary: m['summary'] as String? ?? '',
  );

  static int? _parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}
