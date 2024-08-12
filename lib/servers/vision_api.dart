import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VisionApi {
  static Future<String> detectLabelsFromMemory(Uint8List imageBytes) async {
    // API 키 및 URL 설정
    final apiKey = dotenv.env['GOOGLE_VISION_KEY'];
    if (apiKey == null) {
      throw Exception('Google Vision API key is missing in environment variables');
    }
    
    final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    // 이미지를 Base64 인코딩
    final base64Image = base64Encode(imageBytes);

    // API 요청 전송
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [{'type': 'LABEL_DETECTION', 'maxResults': 10}],
          }
        ],
      }),
    );

    // API 응답 처리
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final labels = (result['responses'][0]['labelAnnotations'] as List)
          .map((annotation) => annotation['description'])
          .join(', ');
      return labels;
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception('Error: ${response.statusCode}, Response: ${errorResponse}');
    }
  }
}
