import 'package:google_generative_ai/google_generative_ai.dart';
import 'gemini_service.dart';

class SupportChatService {
  final GenerativeModel _model;

  SupportChatService() : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: GeminiService.apiKey,
  );

  Future<String> sendMessage(String userText) async {
    try {
      final content = [Content.text(userText)];
      final response = await _model.generateContent(content);
      return response.text ?? 'No response';
    } catch (e) {
      return "Chat Error: $e";
    }
  }
}
