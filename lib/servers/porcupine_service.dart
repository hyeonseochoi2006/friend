import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PorcupineService {
  PorcupineManager? _porcupineManager;
  final Function(int) _wakeWordCallback;

  PorcupineService(this._wakeWordCallback);

  Future<void> initialize() async {
    String keywordPath = "assets/otherkeyword/Hi-Gemini_en_android_v3_0_0.ppn";
    String accessKey = dotenv.env['PORCUPINE_ACCESS_KEY2']!;

    _porcupineManager = await PorcupineManager.fromKeywordPaths(
      accessKey,
      [keywordPath],
      _wakeWordCallback,
    );

    await _porcupineManager!.start();
  }

  Future<void> stop() async {
    await _porcupineManager?.stop();
    _porcupineManager?.delete();
  }
}
