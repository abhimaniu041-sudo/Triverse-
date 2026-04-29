import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel model;

  GeminiService(String apiKey)
      : model = GenerativeModel(
          model: 'gemini-1.5-pro',
          apiKey: apiKey,
        );

  Future<String> generate(String prompt) async {
    final response = await model.generateContent(
      [Content.text(prompt)],
    );

    return response.text ?? "No response";
  }
}
