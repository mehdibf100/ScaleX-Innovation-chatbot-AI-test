// lib/models/ai_model.dart
enum AiModel { groq, mistral, gemini }

extension AiModelName on AiModel {
  String get name {
    switch (this) {
      case AiModel.groq:
        return 'Groq';
      case AiModel.mistral:
        return 'Mistral';
      case AiModel.gemini:
        return 'Gemini';
    }
  }
}
