import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'models.dart';

/// Resolves the API base URL.
/// - On web, served by the same Node server -> use same origin (relative).
/// - Override anywhere with: --dart-define=API_BASE=https://my-app.onrender.com
String _resolveBase() {
  const override = String.fromEnvironment('API_BASE', defaultValue: '');
  if (override.isNotEmpty) return override;
  if (kIsWeb) return Uri.base.origin; // same host that served the app
  return 'http://localhost:3000'; // local dev for mobile/desktop builds
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  static final String base = _resolveBase();
  static String? adminToken;

  static Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$base$path').replace(queryParameters: q);

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (adminToken != null) 'Authorization': 'Bearer $adminToken',
      };

  static dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? {} : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'Request failed (${r.statusCode})';
    throw ApiException(msg);
  }

  // ---------------- public ----------------

  static Future<List<Question>> fetchQuestions({String? category}) async {
    final q = (category != null && category != 'All') ? {'category': category} : null;
    final http.Response r;
    try {
      r = await http
          .get(_u('/api/questions', q))
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }
    final data = _decode(r) as List;
    return data.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final r = await http.get(_u('/api/categories'));
    final data = _decode(r) as List;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, int>> vote(int id, String choice) async {
    final r = await http
        .post(_u('/api/questions/$id/vote'),
            headers: _jsonHeaders, body: jsonEncode({'choice': choice}))
        .timeout(const Duration(seconds: 15));
    final j = _decode(r) as Map<String, dynamic>;
    return {'votes_a': j['votes_a'] as int, 'votes_b': j['votes_b'] as int};
  }

  static Future<String> submit(String a, String b, String category) async {
    final r = await http.post(_u('/api/submit'),
        headers: _jsonHeaders,
        body: jsonEncode({'optionA': a, 'optionB': b, 'category': category}));
    final j = _decode(r) as Map<String, dynamic>;
    return (j['message'] ?? 'Submitted!') as String;
  }

  static Future<Map<String, dynamic>> stats() async {
    final r = await http.get(_u('/api/stats'));
    return _decode(r) as Map<String, dynamic>;
  }

  // ---------------- admin ----------------

  static Future<void> adminLogin(String password) async {
    final r = await http.post(_u('/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}));
    final j = _decode(r) as Map<String, dynamic>;
    adminToken = j['token'] as String;
  }

  static void adminLogout() => adminToken = null;

  static Future<List<PendingQuestion>> pending() async {
    final r = await http.get(_u('/api/admin/pending'), headers: _jsonHeaders);
    final data = _decode(r) as List;
    return data.map((e) => PendingQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> approve(int id) async {
    final r = await http.post(_u('/api/admin/questions/$id/approve'), headers: _jsonHeaders);
    _decode(r);
  }

  static Future<void> deleteQuestion(int id) async {
    final r = await http.delete(_u('/api/admin/questions/$id'), headers: _jsonHeaders);
    _decode(r);
  }

  static Future<void> editQuestion(int id, String a, String b, String category) async {
    final r = await http.put(_u('/api/admin/questions/$id'),
        headers: _jsonHeaders,
        body: jsonEncode({'optionA': a, 'optionB': b, 'category': category}));
    _decode(r);
  }
}
