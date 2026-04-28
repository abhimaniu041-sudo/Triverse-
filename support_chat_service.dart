import 'package:google_generative_ai/google_generative_ai.dart';
import 'gemini_service.dart';

class SupportChatService {
  static const _systemPrompt = 
      'You are the TriVerse AI Support Manager. TriVerse is a premium mobile app that allows users to create AI characters, generate music, and manage content. Your goal is to assist users with technical issues and app navigation in a professional, witty, and helpful manner.';

  final GenerativeModel _model;
  late final ChatSession _chat;

  SupportChatService() : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: GeminiService.apiKey,
          // FIX: Naye version 0.4.0+ ke liye Content.model zaroori hai
          systemInstruction: Content.model([TextPart(_systemPrompt)]),
        ) {
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String userText) async {
    try {
      // FIX: Content.text(userText) sahi format hai
      final response = await _chat.sendMessage(Content.text(userText));
      return response.text ?? 'Sorry, I could not generate a reply.';
    } catch (e) {
      return 'Error reaching AI: $e';
    }
  }
}