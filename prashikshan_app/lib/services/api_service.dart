import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../features/resume/models/analysis_result.dart';

class ApiService {
  // 🚀 DYNAMIC BASE URL: Uses confirmed PC IP for Physical Devices
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) {
      // For Emulators: use 'http://10.0.2.2:8000'
      // For Physical Device: use your PC's IP (Confirm with 'ipconfig')
      return 'http://10.28.94.5:8000';
    }
    return 'http://localhost:8000';
  }

  // ─── Persistent AI Chatbot ──────────────────────────────────
  static Future<String> createChatSession() async {
    final Uri url = Uri.parse('$baseUrl/chat/new');
    debugPrint("[API REQ] POST $url");
    try {
      final response = await http.post(url).timeout(const Duration(seconds: 15));
      debugPrint("[API RES] ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['session_id'];
      }
    } catch (e) {
      debugPrint("[API ERR] $e");
    }
    throw Exception('Failed to create chat session');
  }

  static Future<List<dynamic>> getChatSessions() async {
    final Uri url = Uri.parse('$baseUrl/chat/sessions');
    debugPrint("[API REQ] GET $url");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      debugPrint("[API RES] ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("[API ERR] $e");
    }
    throw Exception('Failed to load chat history');
  }

  static Future<List<dynamic>> getChatMessages(String sessionId) async {
    final Uri url = Uri.parse('$baseUrl/chat/sessions/$sessionId');
    debugPrint("[API REQ] GET $url");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      debugPrint("[API RES] ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("[API ERR] $e");
    }
    throw Exception('Failed to load messages');
  }

  static Future<String> sendChatMessage({
    required String message,
    required String sessionId,
  }) async {
    final Uri url = Uri.parse('$baseUrl/chat/send');
    debugPrint("[API REQ] POST $url | JSON: $message");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'session_id': sessionId,
        }),
      ).timeout(const Duration(seconds: 15));
      debugPrint("[API RES] ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reply'] as String? ?? 'No response';
      }
    } catch (e) {
      debugPrint("[API ERR] $e");
    }
    throw Exception('Chat failed');
  }

  // ─── Modular Resume Analysis API (Multipart) ──────────────
  static Future<AnalysisResult> analyzeResumeMatch({
    required PlatformFile resumeFile,
    required String jdText,
  }) async {
    final Uri url = Uri.parse('$baseUrl/analyze-resume');
    debugPrint("[API REQ] POST $url (Multipart)");
    
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['jd_text'] = jdText
        ..files.add(await http.MultipartFile.fromPath(
          'resume',
          resumeFile.path!,
        ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("[API RES] ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint("[API DATA] $data");
        return AnalysisResult.fromJson(data);
      }
    } catch (e) {
      debugPrint("[API ERR] $e");
    }
    throw Exception('Analysis failed');
  }

  // ─── ML Domain Prediction ──────────────────────────────────
  static Future<String> predictDomain(String text) async {
    final Uri url = Uri.parse('$baseUrl/predict');
    debugPrint("[API REQ] POST $url | Text: $text");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      ).timeout(const Duration(seconds: 15));
      debugPrint("[API RES] ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['domain'] as String;
      }
    } catch (e) {
      debugPrint("[API ERR] $e");
    }
    return "Unknown";
  }

  // ─── Job Feed Recommendations ──────────────────────────────
  static Future<List<dynamic>> getRecommendations(List<String> domains) async {
    final Uri url = Uri.parse('$baseUrl/feed');
    debugPrint("[API REQ] POST $url | domains: $domains");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'domains': domains, 'limit': 50}),
      ).timeout(const Duration(seconds: 15));
      debugPrint("[API RES] ${response.statusCode}");
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint("[API ERR] getRecommendations: $e");
    }
    return [];
  }
}
