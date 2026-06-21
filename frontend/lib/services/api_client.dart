import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

const baseUrl = 'http://localhost:8001';

class ApiClient {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String path, {Map<String, String?>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v ?? '')),
    );
    final res = await http.get(uri, headers: await _headers());
    return _handle(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? 'エラーが発生しました');
    }
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode >= 400) {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      throw Exception(body['detail'] ?? 'エラーが発生しました');
    }
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}
