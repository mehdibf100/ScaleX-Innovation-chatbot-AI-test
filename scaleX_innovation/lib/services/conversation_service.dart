// lib/services/conversation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scalex_innovation/models/conversation.dart';

class ConversationService {

  static const String defaultBaseUrl = 'https://scalex-innovation-backend.up.railway.app/api';

  final String baseUrl;
  final http.Client _client;

  ConversationService({http.Client? client})
      : baseUrl = defaultBaseUrl,
        _client = client ?? http.Client();

  Uri _uri(String path) {
    if (!path.startsWith('/')) path = '/$path';
    return Uri.parse('$baseUrl$path');
  }

  Future<int> createRemoteConversation({required String firebaseUid, String? title}) async {
    final res = await _client.post(
      _uri('/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebaseUid': firebaseUid, 'title': title}),
    );
    if (res.statusCode == 201) {
      final body = jsonDecode(res.body);
      return body['conversationId'] as int;
    } else {
      throw Exception('Erreur createRemoteConversation: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> addRemoteMessage({
    required int remoteConversationId,
    required String firebaseUid,
    required String content,
    required bool isFromUser,
  }) async {
    final res = await _client.post(
      _uri('/conversations/$remoteConversationId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebaseUid': firebaseUid, 'content': content, 'isFromUser': isFromUser}),
    );
    if (res.statusCode != 201) {
      throw Exception('Erreur addRemoteMessage: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> updateRemoteSummary({
    required int remoteConversationId,
    required String firebaseUid,
    required String summary,
  }) async {
    final res = await _client.put(
      _uri('/conversations/$remoteConversationId/summary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebaseUid': firebaseUid, 'summary': summary}),
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur updateRemoteSummary: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteRemoteConversation({required int remoteConversationId, required String firebaseUid}) async {
    final uri = _uri('/conversations/$remoteConversationId').replace(queryParameters: {'firebaseUid': firebaseUid});
    final res = await _client.delete(uri);
    if (res.statusCode != 200) {
      throw Exception('Erreur deleteRemoteConversation: ${res.statusCode} ${res.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRemoteConversations({required String firebaseUid}) async {
    final uri = _uri('/conversations').replace(queryParameters: {'firebaseUid': firebaseUid});
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as List;
      return body.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Erreur fetchRemoteConversations: ${res.statusCode} ${res.body}');
    }
  }

  Future<Map<String, dynamic>> fetchRemoteConversationDetail({required int remoteConversationId, required String firebaseUid}) async {
    final uri = _uri('/conversations/$remoteConversationId').replace(queryParameters: {'firebaseUid': firebaseUid});
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } else {
      throw Exception('Erreur fetchRemoteConversationDetail: ${res.statusCode} ${res.body}');
    }
  }

  Future<Map<String, dynamic>> createRemoteSummary({
    int? remoteConversationId,
    required String firebaseUid,
    required String summary,
    String? context,
  }) async {
    final body = jsonEncode({
      'firebaseUid': firebaseUid,
      if (remoteConversationId != null) 'conversationId': remoteConversationId,
      if (context != null) 'context': context,
      'summary': summary,
    });

    final res = await _client.post(
      _uri('/summary'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return Map<String, dynamic>.from(decoded as Map);
    } else {
      throw Exception('Erreur createRemoteSummary: ${res.statusCode} ${res.body}');
    }
  }

  Future<List<Map<String, dynamic>>> listRemoteSummaries({required String firebaseUid}) async {
    final uri = _uri('/summary').replace(queryParameters: {'firebaseUid': firebaseUid});
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as List;
      return body.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Erreur listRemoteSummaries: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> syncLocalToRemote({required Conversation local, required String firebaseUid}) async {
    if (local.remoteId == null) {
      final remoteId = await createRemoteConversation(firebaseUid: firebaseUid, title: local.title);
      local.remoteId = remoteId;
    }

    if (local.remoteId == null) throw Exception('remoteId null après création');

    for (final m in local.messages) {
      await addRemoteMessage(
        remoteConversationId: local.remoteId!,
        firebaseUid: firebaseUid,
        content: m.content,
        isFromUser: m.role == 'user',
      );
    }

    if (local.summary.isNotEmpty) {
      await updateRemoteSummary(remoteConversationId: local.remoteId!, firebaseUid: firebaseUid, summary: local.summary);
      await createRemoteSummary(remoteConversationId: local.remoteId!, firebaseUid: firebaseUid, summary: local.summary, context: 'sync');
    }
  }
}