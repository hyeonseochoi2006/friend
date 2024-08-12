import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friend/screens/UI_system.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:friend/servers/camerasystem.dart';
import 'package:friend/servers/speech_to_text.dart';
import 'package:friend/servers/Text_to_speech.dart';
import 'package:friend/animation/systeminitial_sub/systeminitial_ani.dart';
import 'package:friend/animation/systeminitial_sub/diamond.dart';
import 'package:friend/servers/Gemini.dart';
import 'package:friend/servers/porcupine_service.dart';

class SystemInitial extends StatefulWidget {
  const SystemInitial({super.key});

  @override
  _SystemInitialState createState() => _SystemInitialState();
}

class _SystemInitialState extends State<SystemInitial> with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService();
  final GoogleTTS _googleTTS = GoogleTTS();
  final GeminiApi _geminiApi = GeminiApi();
  CameraController? _controller;
  String _labels = 'Listening...';
  bool _isListening = false;
  bool _isCameraInitialized = false;
  final Animations _animations = Animations();
  late PorcupineService? _porcupineService;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _animations.initializeAnimations(this, 150.0);
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

  Future<void> _initializePorcupine() async {
    _porcupineService = PorcupineService(_wakeWordCallback);
    await _porcupineService?.initialize();
  }

  void _wakeWordCallback(int keywordIndex) {
    if (keywordIndex == 0) {
      _porcupineService?.stop(); // Stop Porcupine service on wake word detection
      _handleWakeWordDetected();
    }
  }

  void _handleWakeWordDetected() async {
  setState(() {
    _labels = 'Hi, Nice meet you!';
    _isListening = true;
  });

  await _googleTTS.speak('Hi, Nice meet you!');
  

  await Future.delayed(const Duration(seconds: 5));

  // Dispose the camera before navigating to the next page
  _controller?.dispose();
  _controller = null;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const UiSystem()),
  );
}
  void _startAnimation() async {
    await Future.delayed(const Duration(seconds: 1));
    _animations.animationController.forward().then((_) async {
      await Future.delayed(const Duration(seconds: 1));
      _animations.iconAnimationController.forward().then((_) {
        _animations.boxAnimationController.forward().then((_) async {
          _showWakeWordPrompt();
        });
      });
    });
  }

  void _showWakeWordPrompt() {
    setState(() {
      _labels = "Say hi Gemini";
      _isListening = true; 
    });

    
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _isListening = false;
      });
    });
  }

  @override
  void dispose() {
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
          // Main Animation
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
                      scale: _animations.sizeAnimation.value / 150.0,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Center(
              child: Image.asset(
                'assets/google-gemini-icon.png',
                width: 150.0,
                height: 150.0,
              ),
            ),
          ),
          // Gemini Logo Animation
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
          // Camera Preview with Animation
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
                        width: 300.0,
                        height: 300.0,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Listening State (Transparent Overlay)
          if (_isListening)
            Center(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Text(
                    _labels,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
