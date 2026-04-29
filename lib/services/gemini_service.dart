import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';

class GeminiService {
  // TODO: Replace with your actual Gemini API Key from https://aistudio.google.com/app/apikey
  static const String apiKey = 'YOUR_GEMINI_API_KEY';

  /// `kind` is 'app' | 'game' — logged in aiLogs collection.
  static Future<String?> generateCode({
    required BuildContext context,
    required String prompt,
    required int credits,
    required String kind,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('processUsage');
      await callable.call(<String, dynamic>{
        'cost': credits,
        'credits': credits,
        'kind': kind,
        'prompt': prompt,
      });

      final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
      final response = await model.generateContent([
        Content.text(
            'Write Flutter/Dart code for: $prompt. Return ONLY valid Dart code, wrapped in a complete single main.dart file.')
      ]);
      return response.text;
    } catch (e) {
      if (e is FirebaseFunctionsException && e.code == 'resource-exhausted') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Limit Reached (₹1000). Need Admin Approval.',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ));
      }
      return null;
    }
  }

  /// Backwards-compat shim for the old generator signature.
  static Future<String?> generateAppCode(
      BuildContext context, String prompt, int cost) {
    return generateCode(
        context: context, prompt: prompt, credits: cost, kind: 'app');
  }
}
