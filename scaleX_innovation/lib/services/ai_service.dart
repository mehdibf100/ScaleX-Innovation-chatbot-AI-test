import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scalex_innovation/models/ai_model.dart';

class AiService {
  final _secure = const FlutterSecureStorage();

  Future<String?> _getKey(AiModel model) async {
    String? fromEnv;
    switch (model) {
      case AiModel.groq:
        fromEnv = dotenv.env['GROQ_API_KEY'];
        break;
      case AiModel.mistral:
        fromEnv = dotenv.env['MISTRAL_API_KEY'];
        break;
      case AiModel.gemini:
        fromEnv = dotenv.env['GEMINI_API_KEY'];
        break;
    }
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();

    switch (model) {
      case AiModel.groq:
        return await _secure.read(key: 'GROQ_API_KEY');
      case AiModel.mistral:
        return await _secure.read(key: 'MISTRAL_API_KEY');
      case AiModel.gemini:
        return await _secure.read(key: 'GEMINI_API_KEY');
    }
  }

  Future<String> sendMessage({
    required AiModel model,
    required List<Map<String, String>> messages,
    String userLang = 'en',
  }) async {
    final key = await _getKey(model);
    if (key == null || key.isEmpty) {
      throw 'API key for $model not configured. Put it in .env or secure storage.';
    }

    if (model == AiModel.groq) {
      return await _callGroq(key, messages);
    } else if (model == AiModel.mistral) {
      return await _callMistral(key, messages);
    } else if (model == AiModel.gemini) {
      return await _callGemini(key, messages);
    } else {
      throw 'Model not supported';
    }
  }

  // --- Gemini ---
  Future<String> _callGemini(String key, List<Map<String, String>> messages) async {
    String envModel = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';
    String model = envModel.trim();
    final baseUrl = 'https://generativelanguage.googleapis.com/v1/models/$model:generateContent';
    Uri uri = Uri.parse(baseUrl);

    final apiMessages = messages.map((m) {
      final role = (m['role']?.toLowerCase() == 'assistant') ? 'model' : 'user';
      return {
        'role': role,
        'parts': [
          {'text': m['content'] ?? ''}
        ]
      };
    }).toList();

    final payload = {
      'contents': apiMessages,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'candidateCount': 1,
      }
    };

    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (key.startsWith('AIza')) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, 'key': key});
    } else {
      headers['Authorization'] = 'Bearer $key';
    }

    try {
      final res = await http.post(uri, headers: headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 90));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded.containsKey('candidates')) {
          final candidates = decoded['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final candidate = candidates[0];
            if (candidate['content'] != null && candidate['content']['parts'] != null) {
              final parts = candidate['content']['parts'] as List;
              if (parts.isNotEmpty && parts[0]['text'] is String) {
                return (parts[0]['text'] as String).trim();
              }
            }
          }
        }
        throw 'Gemini: Unexpected response format';
      } else {
        // handle common HTTP errors with clearer messages
        if (res.statusCode == 400) throw 'Gemini 400 Bad Request — check model or payload.';
        if (res.statusCode == 401) throw 'Gemini 401 Unauthorized — invalid key.';
        if (res.statusCode == 403) throw 'Gemini 403 Forbidden — check IAM or API activation.';
        if (res.statusCode == 429) throw 'Gemini 429 Rate limited.';
        if (res.statusCode == 503) throw 'Gemini 503 Service unavailable.';
        throw 'Gemini API error ${res.statusCode}: ${res.body}';
      }
    } on SocketException {
      throw 'No internet connection';
    } on TimeoutException {
      throw 'Timeout - Gemini server took too long to respond';
    } catch (e) {
      rethrow;
    }
  }

  // --- Groq ---
  Future<String> _callGroq(String key, List<Map<String, String>> messages) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final payload = {
      'model': 'llama-3.3-70b-versatile',
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 1200,
      'top_p': 0.95,
    };

    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    }, body: jsonEncode(payload)).timeout(const Duration(seconds: 60));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded['choices'] != null && decoded['choices'].isNotEmpty) {
        final choice = decoded['choices'][0];
        if (choice['message'] != null && choice['message']['content'] != null) {
          final content = choice['message']['content'];
          if (content is String) return content.trim();
          if (content is Map && content['parts'] != null) return (content['parts'] as List).join(' ').trim();
        }
        if (choice['text'] != null) return (choice['text'] as String).trim();
      }
      throw 'Groq: Unexpected response format';
    } else {
      throw 'Groq API error ${res.statusCode}: ${res.body}';
    }
  }

  // --- Mistral ---
  Future<String> _callMistral(String key, List<Map<String, String>> messages) async {
    final uri = Uri.parse('https://api.mistral.ai/v1/chat/completions');
    final payload = {'model': 'mistral-large-latest', 'messages': messages, 'temperature': 0.7};

    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    }, body: jsonEncode(payload)).timeout(const Duration(seconds: 90));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['choices'] != null && decoded['choices'].isNotEmpty) {
        final choice = decoded['choices'][0];
        if (choice['message'] != null) {
          final message = choice['message'];
          if (message['content'] is String) return (message['content'] as String).trim();
          if (message['content'] is Map && message['content']['parts'] != null) {
            return (message['content']['parts'] as List).join(' ').trim();
          }
        }
        if (choice['text'] != null) return (choice['text'] as String).trim();
      }
      throw 'Mistral: Unexpected response format';
    } else {
      throw 'Mistral API error ${res.statusCode}: ${res.body}';
    }
  }

  Future<String> summarizeHistory(AiModel model, List<String> userMessages) async {
    final combined = userMessages.take(200).join('\n');
    final messages = [
      {'role': 'system', 'content': 'You are a helpful assistant. Produce a short, clear summary of the user needs.'},
      {'role': 'user', 'content': 'Summarize these messages in a concise bullet list:\n$combined'},
    ];
    return await sendMessage(model: model, messages: messages);
  }
}