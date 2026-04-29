import 'package:google_generative_ai/google_generative_ai.dart';
import 'gemini_service.dart';

class SupportChatService {
  final GenerativeModel _model;
  late final ChatSession _chat;

  SupportChatService() : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: GeminiService.apiKey,
    systemInstruction: Content.model([TextPart('You are TriVerse AI Support.')]),
  ) {
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String userText) async {
    final response = await _chat.sendMessage(Content.text(userText));
    return response.text ?? 'Error';
  }
}
