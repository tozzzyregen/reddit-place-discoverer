import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static String get baseUrl {
    final url = dotenv.env['API_URL'] ?? 'http://localhost:8001';
    print('DEBUG: API_URL from env = $url');
    return url;
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final fullUrl = '$baseUrl/$endpoint';
      print('DEBUG: Making request to: $fullUrl');
      
      final url = Uri.parse(fullUrl);
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('DEBUG: Request timed out!');
          throw Exception('Connection timed out');
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('API Client Error: $e');
      return null;
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final fullUrl = '$baseUrl/$endpoint';
      print('DEBUG: POST request to: $fullUrl');
      
      final url = Uri.parse(fullUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('DEBUG: Request timed out!');
          throw Exception('Connection timed out');
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('API Client Error: $e');
      return null;
    }
  }
}

