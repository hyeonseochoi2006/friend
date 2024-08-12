import 'dart:typed_data';

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
      String? fullResponse = response.text ?? 'error';

      // 중요 부분만 추출
      String importantPart = _extractImportantPart(fullResponse);

      return importantPart;
    } catch (e) {
      throw Exception('Content generation failed: $e');
    }
  }

  // Vision API의 감지 결과에 기반하여 설명을 생성하는 메서드
  Future<String?> generateDescriptionFromImage(Uint8List imageBytes) async {
    try {
      final labels = await VisionApi.detectLabelsFromMemory(imageBytes);
      final prompt = 'The image contains the following objects: $labels. Based on this, provide a single, free-form comment or thought.';
      return await generateContent(prompt);
    } catch (e) {
      throw Exception('Failed to generate description: $e');
    }
  }

  // 응답에서 중요한 부분을 추출하는 메서드
  String _extractImportantPart(String response) {
  // 특정 키워드가 포함된 문장을 추출
  List<String> sentences = response.split('.');
  for (var sentence in sentences) {
    if (sentence.contains('important keyword')) {
      return sentence.trim() + '.';
    }
  }
  // 특정 키워드가 없으면 첫 번째 문장 반환
  return sentences.first.trim() + '.';
}
}
