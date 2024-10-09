import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class GeminiApi {
  Future<String> sendMessage(String message) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$API_KEY'); // Menggunakan API_KEY dari config.dart

    // Logging request
    print('Requesting API: $url');
    print('Headers: ${{
      'Content-Type': 'application/json',
    }}');
    print('Body: ${jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': message,
            }
          ]
        }
      ]
    })}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': message,
                }
              ]
            }
          ]
        }),
      );

      // Logging response
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      print('Error: $e');  // Log any exceptions
      return 'Failed to connect to Gemini API: $e';
    }
  }
}
