import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleSTT {
  final String _apiKey = dotenv.env['GOOGLE_STT_APIKEY']!;

  Future<String?> transcribeAudio(String filePath) async {
    try {
      // 음성 파일을 base64로 인코딩
      final bytes = File(filePath).readAsBytesSync();
      if (bytes.isEmpty) {
        print("파일이 비어 있습니다.");
        return null;
      }
      final String audioContent = base64Encode(bytes);

      // API 요청을 위한 JSON 데이터 생성
      final Map<String, dynamic> request = {
        'config': {
          'encoding': 'LINEAR16',
          'sampleRateHertz': 16000,
          'languageCode': 'en-US',
        },
        'audio': {
          'content': audioContent,
        },
      };

      // API 요청
      final response = await http.post(
        Uri.parse('https://speech.googleapis.com/v1/speech:recognize?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request),
      );

      // API 응답 처리
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print("API 응답: ${jsonResponse.toString()}"); // 응답 로그 추가
        if (jsonResponse['results'] != null && jsonResponse['results'].isNotEmpty) {
          final StringBuffer transcripts = StringBuffer();
          for (var result in jsonResponse['results']) {
            final transcript = result['alternatives'][0]['transcript'] as String?;
            if (transcript != null) {
              transcripts.write(transcript + " ");
            }
          }
          return transcripts.toString().trim();
        } else {
          print("STT 결과가 없습니다.");
          return null; // transcript가 없을 경우 null 반환
        }
      } else {
        print('Error: ${response.statusCode} ${response.reasonPhrase}');
        print('Response body: ${response.body}'); // 응답 본문 로그 추가
        return null; // 오류 발생 시 null 반환
      }
    } catch (e) {
      print('Exception caught: $e');
      return null; // 예외 발생 시 null 반환
    }
  }
}
