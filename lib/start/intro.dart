import 'package:flutter/material.dart';
import 'package:friend/servers/Text_to_speech.dart';
import 'package:friend/servers/speech_to_Text.dart';
import 'package:friend/screens/UI_system.dart';
import 'package:friend/screens/SystemInitial.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class IntroSystem extends StatefulWidget {
  const IntroSystem({super.key});

  @override
  _IntroSystemState createState() => _IntroSystemState();
}

class _IntroSystemState extends State<IntroSystem> with SingleTickerProviderStateMixin {
  final GoogleTTS _googleTTS = GoogleTTS();
  final GoogleSTT _googleSTT = GoogleSTT();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _textfinalsound = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
   final AudioPlayer _backgroundMusicPlayer = AudioPlayer();

  String _displayText = '';
  double _opacity = 0.0;
  String _recordedFilePath = '';
  bool _isRecording = false;
  bool _isTranscribing = false;

  final double _starSize = 150.0; // 이미지 크기 조정
  late AnimationController _controller;
  late Animation<double> _floatingAnimation;
  late Animation<double> _rotatingAnimation;

  @override
  void initState() {
    _playBackgroundMusic();
 
    super.initState();
    _initializeRecorder();
    _speakWelcomeMessage();
 

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -20, end: 20).animate(_controller);
    _rotatingAnimation = Tween<double>(begin: 0, end: 2 * 3.14).animate(_controller);
  }

  @override
  void dispose() {
     _backgroundMusicPlayer.stop();
    _audioPlayer.stop();
    _recorder.closeRecorder();
    _textfinalsound.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print("Microphone permission denied");
      return;
    }

    try {
      await _recorder.openRecorder();
      print("Recorder opened successfully");
    } catch (e) {
      print("Error opening recorder: $e");
    }
  }
  Future<void> _playBackgroundMusic() async {
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundMusicPlayer.setVolume(0.2);
    await _backgroundMusicPlayer.play(AssetSource('intromusic.mp3'));
  }
  
  Future<void> _speakWelcomeMessage() async {
    await _showTextAndSpeak("HI", 2);
    await _showTextAndSpeak("Nice to meet you", 3);
    await _showTextAndSpeak("My name is Gemini", 3);
    await _showTextAndSpeak("I want to be your friend!", 3);
  
    await _showTextAndSpeak("If you don't mind, please answer Yes.", 2);
    bool recordingStarted = await _startRecording();
    if (!recordingStarted) {
      await _showTextAndSpeak("Recording failed. Please try again.", 3);
      _recordingSection();
      return;
    }
    await Future.delayed(const Duration(seconds: 5));
    bool recordingStopped = await _stopRecording();

    if (!recordingStopped) {
      await _showTextAndSpeak("No valid recording found. Please try again.", 3);
      _recordingSection();
      return;
    }

    String? transcribedText = await _showTranscribingStar();


    if (transcribedText!.toLowerCase().contains('ok') || transcribedText.toLowerCase().contains('yes')) {
      _backgroundMusicPlayer.stop();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SystemInitial()),
      );
    } else {
      _recordingSection();
    }
  }

  Future<void> _recordingSection() async {
    
    await _showTextAndSpeak("Please try again.", 3);
    bool recordingStarted = await _startRecording();
    if (!recordingStarted) {
      await _showTextAndSpeak("Recording failed. Please try again.", 3);
      _recordingSection();
      return;
    }
    await Future.delayed(const Duration(seconds: 5));
    bool recordingStopped = await _stopRecording();

    if (!recordingStopped) {
      await _showTextAndSpeak("No valid recording found. Please try again.", 3);
      _recordingSection();
      return;
    }

    String? transcribedText = await _showTranscribingStar();
    print(transcribedText);

    if (transcribedText!.toLowerCase().contains('ok') || transcribedText.toLowerCase().contains('okay')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SystemInitial()),
      );
    } else {
      
      _recordingSection();
    }
  }

  Future<void> _showTextAndSpeak(String text, int delayInSeconds, {Function? onComplete}) async {
  setState(() {
    _displayText = text;
    _opacity = 1.0;
  });
  try {
    await _googleTTS.speak(text, onComplete: onComplete); // onComplete 콜백 추가
  } catch (e) {
    print("TTS failed: $e");
  }
  await Future.delayed(Duration(seconds: delayInSeconds));
  setState(() {
    _opacity = 0.0;
  });
}


  Future<bool> _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _recordedFilePath = '${tempDir.path}/recorded_audio.wav';
      await _recorder.startRecorder(
        toFile: _recordedFilePath,
        codec: Codec.pcm16WAV,
      );
      print("Recording started at $_recordedFilePath");
      setState(() {
        _isRecording = true;
      });
      return true;
    } catch (e) {
      print("Recording failed: $e");
      setState(() {
        _isRecording = false;
      });
      return false;
    }
  }

  Future<bool> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      print("Recording stopped");
      setState(() {
        _isRecording = false;
      });

      File recordedFile = File(_recordedFilePath);
      if (!recordedFile.existsSync() || recordedFile.lengthSync() < 1024) { // 1KB 미만이면 실패로 간주
        print("Recording file is too small or does not exist.");
        return false;
      }

      return true;
    } catch (e) {
      print("Stop recording failed: $e");
      setState(() {
        _isRecording = false;
      });
      return false;
    }
  }

  Future<String?> _transcribeRecording() async {
    if (_recordedFilePath.isNotEmpty && File(_recordedFilePath).existsSync()) {
      return await _googleSTT.transcribeAudio(_recordedFilePath);
    } else {
      return 'No recording available';
    }
  }

  Future<String?> _showTranscribingStar() async {
    setState(() {
      _isTranscribing = true;
    });
    String? transcribedText = await _transcribeRecording();
    setState(() {
      _isTranscribing = false;
    });

    if (transcribedText == 'No recording available') {
      await _showTextAndSpeak("No valid recording found. Please try again.", 3);
      _recordingSection();
    }

    return transcribedText;
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(243, 3, 1, 51),
      body: Stack(
        children: [
          Center(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 1),
              child: Text(
                _displayText,
                style: const TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_isRecording)
            Center(
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: Image.asset(
                      'assets/google-gemini-icon.png',
                      width: _starSize,
                      height: _starSize,
                    ),
                  );
                },
              ),
            ),
          if (_isTranscribing)
            Center(
              child: AnimatedBuilder(
                animation: _rotatingAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotatingAnimation.value,
                    child: Image.asset(
                      'assets/google-gemini-icon.png',
                      width: _starSize,
                      height: _starSize,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
