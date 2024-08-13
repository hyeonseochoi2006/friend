import 'package:friend/servers/Text_to_speech.dart';
import 'package:friend/screens/UI_system.dart';

class FriendServer {
  final GoogleTTS _googleTTS = GoogleTTS();

  // 특정 입력에 따라 응답을 처리하는 메서드
  Future<String?> handleResponse(String input, Function startListening) async {
    String? response;
    if (input.toLowerCase().contains('hi')) {
      response = "What's up?";
      await _respondWith(response, startListening);
    } else if (input.toLowerCase().contains('could you please ')) {
      response = "Okay, I will introduce😊";
      // response = "okay, That's good! Hi guys! I'm Gemini, an artificial intelligence model, and I'm in an app called friend, and my voice comes from TTS, which is my vocal cords, and STT is a language that I can understand. In addition to my vocal cords, I can analyze the world outside through Google vision. ";
      await _respondWith(response, startListening);
    
    }else if (input.toLowerCase().contains('introduce yourself')) {
      response = "No, but, speak slowly and I'll tell you";
      await _respondWith(response, startListening);
    }else if (input.toLowerCase().contains('come on') || input.toLowerCase().contains('fast')) {
      response = "No,no,too fast";
      await _respondWith(response, startListening);
    }
    else if (input.toLowerCase().contains('perfect')) {
      response = "shut up";
      await _respondWith(response, startListening);
    }
    
    return response; // Return the response if handled, null otherwise
  }

  // 텍스트로 응답하는 메서드
  Future<void> _respondWith(String response, Function startListening) async {
    await _googleTTS.speak(response, onComplete: startListening);
  }
}
