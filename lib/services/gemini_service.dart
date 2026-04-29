import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String apiKey = "YOUR_API_KEY_HERE"; // Apni key dalo

  static Future<String> getAiResponse(String prompt) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "No response from AI";
    } catch (e) {
      return "AI Error: $e";
    }
  }
}
