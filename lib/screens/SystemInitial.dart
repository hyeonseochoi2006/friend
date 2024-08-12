import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:friend/servers/camerasystem.dart';
import 'package:friend/servers/speech_to_text.dart';
import 'package:friend/servers/Text_to_speech.dart';
import 'package:friend/animation/systeminitial_sub/systeminitial_ani.dart';
import 'package:friend/animation/systeminitial_sub/diamond.dart';
import 'package:friend/servers/Gemini.dart';
import 'package:friend/servers/porcupine_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class SystemInitial extends StatefulWidget {
  const SystemInitial({super.key});

  @override
  _SystemInitialState createState() => _SystemInitialState();
}

class _SystemInitialState extends State<SystemInitial> with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService();
  final GoogleSTT _googleSTT = GoogleSTT();
  final GoogleTTS _googleTTS = GoogleTTS();
  final FlutterSoundRecorder _voiceRecorder = FlutterSoundRecorder();
  final FlutterSoundRecorder _backgroundRecorder = FlutterSoundRecorder();
  // final AudioPlayer _audioPlayer = AudioPlayer();
  final GeminiApi _geminiApi = GeminiApi();
  CameraController? _controller;
  String _labels = 'Listening...';
  bool _isListening = false;
  bool _isRecording = false;
  bool _isDetecting = false;
  int _retryCount = 0;
  int _currentThreshold = 40;
  Timer? _timer;
  Timer? _silenceTimer;
  final double _initialStarSize = 150.0;
  final double _finalCameraSize = 300.0;
  bool _isCameraInitialized = false;
  final Animations _animations = Animations();
  late PorcupineService? _porcupineService;
  


  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAudio();
    _animations.initializeAnimations(this, _initialStarSize);
    _startAnimation();
    _initializePorcupine();
  
    
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initializeCamerasystem();
    _controller = _cameraService.controller;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _initializeAudio() async {
    await _voiceRecorder.openRecorder();
    
  }

  Future<void> _initializePorcupine() async {
    _porcupineService = PorcupineService(_wakeWordCallback);
    await _porcupineService?.initialize();
  }

  void _wakeWordCallback(int keywordIndex) {
  if (keywordIndex == 0) {
    _porcupineService?.stop(); // 웨이크 워드가 감지되면 Porcupine 서비스 중지
    _startListening();
  }
}

Future<void> _startListening() async {
  if (_voiceRecorder.isRecording) {
    print('녹음기가 이미 실행 중입니다');
    return;
  }

  await _voiceRecorder.openRecorder();
  setState(() {
    _isListening = true;
    _animations.recordRotationController.repeat();
  });

  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/temp_audio.wav';

  await _voiceRecorder.startRecorder(
    toFile: path,
    codec: Codec.pcm16WAV,
  );

  _isRecording = true;

  // 10초 후에 녹음을 자동으로 중지하고 처리 시작
  await Future.delayed(const Duration(seconds: 10));
  await stopRecording();
}

Future<void> stopRecording() async {
  if (!_isRecording) return;

  await _voiceRecorder.stopRecorder();
  await _voiceRecorder.closeRecorder();

  _isRecording = false;

  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/temp_audio.wav';

  final transcript = await _googleSTT.transcribeAudio(path);

  if (transcript == null || transcript.isEmpty) {
    _retryCount++;

    if (_retryCount == 1) {
      setState(() {
        _labels = "Please say again";
      });
      _startListening(); // 다시 듣기 시도
    } else {
      setState(() {
        _isListening = false;
        _labels = 'Listening...';
      });
      _retryCount = 0; // 시도 횟수 초기화
      _initializePorcupine();

      return; // 다시 웨이크 워드 감지로 돌아가기
    }
  } else {
    _retryCount = 0; // 성공 시 시도 횟수 초기화

    try {
      final response = await _geminiApi.generateContent(transcript);
      setState(() {
        _labels = response!;
      });

      await _googleTTS.speak(response!, onComplete: _startListening); // 음성 재생 완료 시 _startListening 호출

    } catch (e) {
      setState(() {
        print('Error: ${e.toString()}');
        _labels = 'Sorry, could you say again?';
        _startListening();
      });
    }
  }
}






  void _startAnimation() async {
    await Future.delayed(const Duration(seconds: 1));
    _animations.animationController.forward().then((_) async {
      await Future.delayed(const Duration(seconds: 2));
      _animations.iconAnimationController.forward().then((_) {
        _animations.boxAnimationController.forward().then((_) async  {
          _wakeWordCallback(1);
        });
      });
    });
  }

  @override
  void dispose() {
    _voiceRecorder.closeRecorder();
    _backgroundRecorder.closeRecorder();
    _cameraService.dispose();
    _animations.dispose();
    _porcupineService?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(243, 3, 1, 51),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animations.animationController,
            builder: (context, child) {
              Offset offset = _animations.animationController.value < 0.6
                  ? _animations.positionAnimation.value * MediaQuery.of(context).size.width / 2
                  : _animations.finalRightAnimation.value * MediaQuery.of(context).size.width / 2;

              double opacity = _animations.animationController.value < 0.6
                  ? 1.0
                  : _animations.opacityAnimation.value;

              double rotation = _animations.animationController.value >= 0.6
                  ? _animations.rotationAnimation.value
                  : 0.0;

              return Transform.translate(
                offset: offset,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: _animations.sizeAnimation.value / _initialStarSize,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Center(
              child: Image.asset(
                'assets/google-gemini-icon.png',
                width: _initialStarSize,
                height: _initialStarSize,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _animations.geminiLogoAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _animations.geminiLogoAnimation.value,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: child,
                  ),
                ),
              );
            },
            child: Image.asset(
              'assets/Google_Gemini_logo.svg.png',
              width: 70,
              height: 70,
            ),
          ),
          if (_isCameraInitialized && _controller != null && _controller!.value.isInitialized)
            Center(
              child: AnimatedBuilder(
                animation: _animations.cameraAnimation,
                builder: (context, child) {
                  return ClipPath(
                    clipper: DiamondClipper(),
                    child: Align(
                      alignment: Alignment.center,
                      widthFactor: _animations.cameraAnimation.value,
                      heightFactor: _animations.cameraAnimation.value,
                      child: SizedBox(
                        width: _finalCameraSize,
                        height: _finalCameraSize,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_isListening)
            Positioned(
              bottom: 20, // Adjusted to move the star slightly upwards
              right: 16,
              child: AnimatedBuilder(
                animation: _animations.iconAnimationController,
                builder: (context, child) {
                  Offset offset = _animations.icontalkPositionAnimation.value * MediaQuery.of(context).size.width;
                  double rotation = _animations.icontalkRotationAnimation.value;
                  double opacity = _animations.icontalkOpacityAnimation.value;
                  return Transform.translate(
                    offset: offset,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Opacity(
                        opacity: opacity,
                        child: AnimatedBuilder(
                          animation: _animations.recordRotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _animations.recordRotationController.value * 3.14 * 2,
                              child: child,
                            );
                          },
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/google-gemini-icon.png',
                  width: 70,
                  height: 70,
                ),
              ),
            ),
            if (_isListening)
              Positioned(
                bottom: 16,
                left: 16,
                child: AnimatedBuilder(
                  animation: _animations.boxAnimationController,
                  builder: (context, child) {
                    Offset offset = _animations.boxPositionAnimation.value * MediaQuery.of(context).size.width;
                    double opacity = _animations.boxOpacityAnimation.value;

                    return Transform.translate(
                      offset: offset,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 300,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(122, 33, 149, 243), Color.fromARGB(122, 155, 39, 176)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _labels, // Display the recognized text in the labels
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
