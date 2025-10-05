import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scalex_innovation/models/ai_model.dart';

class EmptyStateWidget extends StatelessWidget {
  final AiModel model;
  const EmptyStateWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String modelName = model == AiModel.groq
        ? 'Groq (Llama 3)'
        : model == AiModel.mistral
        ? 'Mistral.ai'
        : 'Gemini';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'empty_state_icon',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 60),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              tr('empty_state.assistant'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              modelName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('empty_state.welcome'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SuggestionCard(
              icon: Icons.lightbulb_outline,
              title: tr('empty_state.questions_title'),
              description: tr('empty_state.questions_desc'),
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            SuggestionCard(
              icon: Icons.code,
              title: tr('empty_state.code_title'),
              description: tr('empty_state.code_desc'),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            SuggestionCard(
              icon: Icons.article_outlined,
              title: tr('empty_state.write_title'),
              description: tr('empty_state.write_desc'),
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const SuggestionCard(
      {Key? key,
        required this.icon,
        required this.title,
        required this.description,
        required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}