// lib/widgets/messages_list.dart
import 'package:flutter/material.dart';
import 'package:scalex_innovation/models/chat_message.dart';
import 'message_bubbles.dart';

class MessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController controller;

  const MessagesList({Key? key, required this.messages, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final m = messages[i];
        if (m.isDraft) {
          // Draft voice line UI
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        m.content.isEmpty ? '…' : m.content,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // simple "wave" indicator (animated dots could be better)
                    SizedBox(
                      width: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.graphic_eq, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // your existing bubble widgets
          return m.role == 'user' ? UserMessage(text: m.content) : AssistantMessage(text: m.content);
        }
      },
    );
  }
}
