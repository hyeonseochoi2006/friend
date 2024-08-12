import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:friend/Animation/systeminitial_sub/Systeminitial_ani.dart';
import 'package:friend/servers/porcupine_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:friend/Animation/UisystemAnimation/Animation.dart';
import 'package:friend/Animation/UisystemAnimation/shape.dart';
import 'package:friend/servers/Gemini.dart';
import 'package:friend/servers/Text_to_speech.dart';
import 'package:friend/servers/map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:friend/servers/vision_api.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:friend/servers/speech_to_Text.dart'; 
import 'package:flutter_sound/flutter_sound.dart';

class UiSystem extends StatefulWidget {
  const UiSystem({super.key});

  @override
  _UiSystemtState createState() => _UiSystemtState();
}

class _UiSystemtState extends State<UiSystem> with TickerProviderStateMixin {
  CameraController? _cameraController;
  final double _finalCameraSize = 300.0;
  late UiSystemAnimations animations;
  Future<String>? mapUrl;

  bool _isCameraInitialized = false;
  bool _showFullScreenCamera = false;
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isRecording = false;
  bool _isPorcupineActive = true;
  int _remainingTime = 10; // 타이머를 위한 변수 추가

  String _handData = "No hand detected";
  String _geminiResponse = "";
  int _retryCount = 0;
  Timer? _wakeWordTimer;
  Timer? _timer; // 타이머 변수 추가

  PorcupineService? _porcupineService;
  final FlutterSoundRecorder _voiceRecorder = FlutterSoundRecorder();
  final _googleSTT = GoogleSTT();
  final _geminiApi = GeminiApi();
  final _googleTTS = GoogleTTS();

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // Initialize the camera after animations

    animations = UiSystemAnimations(vsync: this);

    animations.animationController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFullScreenCamera = true;
          animations.fadeInController.forward();
          Future.delayed(const Duration(seconds: 2), () async {
            await animations.containerFadeInController.forward();
            await _initializePorcupine(); // Initialize Porcupine after animations
          });
        });
      }
    });

    _startInitialAnimation(); // Start the initial animation
  }

  Future<void> _startInitialAnimation() async {
    animations.animationController.forward();
  }

  Future<void> _initializePorcupine() async {
    _porcupineService = PorcupineService(_wakeWordCallback);
    await _porcupineService?.initialize();
    
  }

  void _wakeWordCallback(int keywordIndex) {
  if (keywordIndex == 0) {
    _porcupineService?.stop();
    _startListening(); // 바로 녹음 시작
    
  }
}

// 타이머 제거
void _startWakeWordTimer() {
  _wakeWordTimer?.cancel(); // 기존 타이머가 있을 경우 취소
  // 더 이상 타이머를 사용하지 않으므로 빈 메서드로 유지
}

  Future<void> _startListening() async {
    if (_voiceRecorder.isRecording) {
      print('Recorder is already running');
      return;
    }

    await _voiceRecorder.openRecorder();
    setState(() {
      _isListening = true;
      _startCountdown(); // 타이머 시작
      animations.recordRotationController.repeat(); // Start icon rotation
    });

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/friend_audio.wav';

    await _voiceRecorder.startRecorder(
      toFile: path,
      codec: Codec.pcm16WAV,
    );

    _isRecording = true;

    // Stop recording after 10 seconds and start processing
    await Future.delayed(const Duration(seconds: 10));
    await stopRecording();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _remainingTime = 10; // 타이머 초기화
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    await _voiceRecorder.stopRecorder();
    await _voiceRecorder.closeRecorder();

    _isRecording = false;
    animations.recordRotationController.stop();
    _timer?.cancel();

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/friend_audio.wav';

    final transcript = await _googleSTT.transcribeAudio(path);

    setState(() {
      _geminiResponse = transcript!;
    });

    if (transcript == null || transcript.isEmpty) {
      _retryCount++;

      if (_retryCount == 1) {
        setState(() {
          _geminiResponse = "";
        });
        _initializePorcupine(); // Retry listening
      }
    } else {
      _retryCount = 0; // Reset retry count on success

      try {
        if (transcript.contains("What can you see") || transcript.contains("see")) {
          setState(() {
            animations.recordRotationController.stop();
          });
          await _analyzeCameraFeed();
          
          
        } else {
          final response = await _geminiApi.generateContent(transcript);
          setState(() {
            _geminiResponse = response!;
            animations.recordRotationController.stop(); // Stop rotation after response
          });

          await _googleTTS.speak(response!, onComplete: _startListening); // Start listening again after TTS
          
        }
      } catch (e) {
        setState(() {
          print('Error: ${e.toString()}');
          _geminiResponse = 'Sorry, could you say again?';
          _startListening();
        });
      }
    }
  }
  

  Future<void> _analyzeCameraFeed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      final description = await GeminiApi().generateDescriptionFromImage(imageBytes);

      setState(() {
        _geminiResponse = description ?? 'I’m here to chat whenever you need a smile!';
      });

      await GoogleTTS().speak(_geminiResponse, onComplete: _startListening);
    } catch (e) {
      print('Error during camera feed analysis: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(243, 3, 1, 51),
      body: Stack(
        children: [
          if (_showFullScreenCamera && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),
          if (!_showFullScreenCamera && _isCameraInitialized && _cameraController != null)
            Center(
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: animations.opacityAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 1.0 - animations.opacityAnimation.value,
                        child: child,
                      );
                    },
                    child: ClipPath(
                      clipper: DiamondClipper(),
                      child: SizedBox(
                        width: _finalCameraSize,
                        height: _finalCameraSize,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: animations.animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: animations.scaleAnimation.value,
                        child: Transform.rotate(
                          angle: animations.rotationAnimation.value,
                          child: Opacity(
                            opacity: animations.opacityAnimation.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: ClipPath(
                      clipper: DiamondClipper(),
                      child: Container(
                        width: _finalCameraSize,
                        height: _finalCameraSize,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AnimatedBuilder(
            animation: animations.logoFadeOutAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: animations.logoFadeOutAnimation.value,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      'assets/Google_Gemini_logo.svg.png',
                      width: 70,
                      height: 70,
                    ),
                  ),
                ),
              );
            },
          ),
          SlideTransition(
            position: animations.iconSlideAnimation,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 40.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: animations.recordRotationController,
                      child: Image.asset(
                        'assets/google-gemini-icon.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SlideTransition(
                      position: animations.labelSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: MediaQuery.of(context).size.width * 0.7,
                          padding: const EdgeInsets.all(12.0),
                          constraints: BoxConstraints(
                            minHeight: 50.0, // Ensure minimum height
                            maxHeight: MediaQuery.of(context).size.height * 0.3, // Ensure maximum height
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: SingleChildScrollView(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _geminiResponse,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                    ),
                                    overflow: TextOverflow.visible,
                                    maxLines: null,
                                  ),
                                ),
                                if (_isListening) // 녹음 중일 때 타이머 표시
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0), // 타이머와 텍스트 사이의 간격
                                    child: Text(
                                      '$_remainingTime',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: animations.jjjFadeInAnimation,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 0.0, bottom: 40.0),
                child: Transform.rotate(
                  angle: 1.5708,
                  child: Image.asset(
                    'assets/Google_Gemini_logo.svg.png',
                    width: 70,
                    height: 70,
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: animations.containerFadeInAnimation,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        SizedBox(height: 10),
                        Text(
                          '• Say "Hi Gemini" to start a conversation.\n'
                          '• Ask "What can you see?" to know more about your surroundings.',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!_isCameraInitialized)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    animations.dispose();
    super.dispose();
    _voiceRecorder.closeRecorder();
    _porcupineService?.stop();
    _timer?.cancel(); // 타이머 종료
  }
}
