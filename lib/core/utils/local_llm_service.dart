import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocalLlmService {
  static final LocalLlmService _instance = LocalLlmService._internal();
  factory LocalLlmService() => _instance;
  LocalLlmService._internal();

  final String _baseUrl = 'http://127.0.0.1:11434/api/generate';
  final String _modelName = 'qwen2.5:0.5b'; // Ultra-lightweight SLM, ideal for fast offline devices

  /// Triage a survivor's raw message using the local Ollama SLM.
  /// Returns a Map containing 'status' (string) and 'needs' (comma-separated string).
  Future<Map<String, dynamic>?> analyzeEmergency(String message) async {
    if (message.trim().isEmpty) return null;

    final systemPrompt = """
You are an offline emergency triage assistant. Analyze the survivor's text and categorize:
1. Urgency: SAFE, INJURED, or CRITICAL. (SAFE: no direct danger or minor requests; INJURED: has injuries or medical needs; CRITICAL: in immediate life-threatening danger, trapped, active bleeding, severe health issue).
2. Needs: A list containing zero or more of: "Food & Water", "First Aid / Medical", "Shelter", "Tools / Warmth".

Respond ONLY with a JSON object in this exact format, with no extra text or markdown:
{
  "urgency": "STATUS",
  "needs": ["NEED1", "NEED2"]
}
""";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _modelName,
          'prompt': "$systemPrompt\n\nSurvivor Message: \"$message\"",
          'stream': false,
          'format': 'json', // Forces Ollama to output valid JSON
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final String responseText = decoded['response'];
        
        // Parse the inner JSON returned by the model
        final parsedJson = jsonDecode(responseText.trim()) as Map<String, dynamic>;
        
        final rawUrgency = parsedJson['urgency']?.toString().toUpperCase() ?? 'INJURED';
        final rawNeedsList = parsedJson['needs'] as List<dynamic>? ?? [];
        
        // Map urgency string to SurvivorStatus enum string representation
        String status = 'safe';
        if (rawUrgency == 'CRITICAL') status = 'critical';
        if (rawUrgency == 'INJURED') status = 'injured';
        
        final cleanNeeds = rawNeedsList.map((e) => e.toString()).toList();
        
        return {
          'status': status,
          'needs': cleanNeeds.join(', '),
        };
      } else {
        debugPrint('Ollama Server responded with error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Local LLM Triage Error: $e');
    }
    return null;
  }
}
