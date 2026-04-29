import 'package:google_generative_ai/google_generative_ai.dart';

class SupportChatService {
  final GenerativeModel model;

  SupportChatService(String apiKey)
      : model = GenerativeModel(
          model: 'gemini-1.5-pro',
          apiKey: apiKey,
        );

  Future<String> send(String text) async {
    final response = await model.generateContent(
      [Content.text(text)],
    );

    return response.text ?? "No reply";
  }
}
