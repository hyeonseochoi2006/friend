import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleTTS {
  final String? apiKey = dotenv.env['GOOGLE_TTS_APIKEY'];

  GoogleTTS() {
    if (apiKey == null) {
      throw Exception('Google TTS API key is missing in environment variables');
    }
  }

  Future<void> speak(String text, {Function? onComplete}) async {
    final url = 'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: json.encode({
        'input': {'text': text},
        'voice': {
          'languageCode': 'en-US',
          'name': 'en-US-Wavenet-D', // 남성 목소리
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
        },
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final audioContent = responseData['audioContent'];
      final audioPlayer = AudioPlayer();
      audioPlayer.onPlayerComplete.listen((event) {
        if (onComplete != null) {
          onComplete(); // 음성 재생이 완료되면 onComplete 호출
        }
      });
      await audioPlayer.play(BytesSource(base64.decode(audioContent)));
    } else {
      final errorMessage = json.decode(response.body)['error']['message'];
      throw Exception('Failed to synthesize speech: $errorMessage');
    }
  }
}
