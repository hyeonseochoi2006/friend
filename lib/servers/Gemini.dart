import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 환경 변수를 가져오기 위한 패키지
import 'vision_api.dart'; // Vision API 코드를 포함하는 파일

class GeminiApi {
  final String _apiKey;
  final GenerativeModel _model;

  // API 키를 초기화하는 생성자
  GeminiApi() 
      : _apiKey = dotenv.env['GEMINI_API_KEY']!,
        _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: dotenv.env['GEMINI_API_KEY']!);

  // 텍스트 콘텐츠를 생성하는 메서드
  Future<String?> generateContent(String prompt) async {
    final content = [Content.text(prompt)];

    try {
      final response = await _model.generateContent(content);
      // 특정 응답을 처리
      if (prompt.toLowerCase() == 'error') {
        return 'error';
      } if (prompt.toLowerCase() == 'hi') {
        return 'Hi Hyeonseo, nice to meet you, good luck in the future, my name is Gemini.';
      }
      return response.text ?? 'error';
    } catch (e) {
      throw Exception('Content generation failed: $e');
    }
  }
}
