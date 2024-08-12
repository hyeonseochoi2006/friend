import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:friend/Animation/UisystemAnimation/Animation.dart';
import 'package:friend/Animation/UisystemAnimation/shape.dart';
import 'package:friend/servers/Gemini.dart';
import 'package:friend/servers/Text_to_speech.dart';
import 'package:friend/servers/map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:friend/servers/vision_api.dart';
import 'package:flutter/services.dart'; // 추가된 import

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

  // 손 위치 데이터에 대한 정보를 저장하는 변수
  String _handData = "No hand detected"; // 초기값 설정

  // MethodChannel 설정
  static const platform = MethodChannel('mediapipe/hand_tracking');

  @override
  void initState() {
    super.initState();

    animations = UiSystemAnimations(vsync: this);
    _initializeCamera();

    animations.animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFullScreenCamera = true;
          animations.fadeInController.forward();
          Future.delayed(const Duration(seconds: 2), () {
            animations.containerFadeInController.forward();
          });
        });

        // Mediapipe 손 추적 시작
        _startHandTracking();

        // 카메라 분석을 일정 간격으로 실행
        Timer.periodic(const Duration(seconds: 5), (timer) {
          _analyzeCameraFeed();
        });
      }
    });

    _getLocationAndMapUrl();  // 위치와 지도를 불러옵니다.
  }

  // Mediapipe 손 추적을 시작하는 메서드
  Future<void> _startHandTracking() async {
    try {
      platform.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'onHandDetected') {
          final handPosition = call.arguments;
          _processHandPosition(handPosition);
        }
      });
    } on PlatformException catch (e) {
      print("Failed to start hand tracking: '${e.message}'.");
    }
  }

  // 손 위치 데이터를 처리하는 메서드
  void _processHandPosition(dynamic handPosition) {
    // 손의 위치 데이터 처리
    List<dynamic> landmarks = handPosition['landmarks'];

    // 예: 첫 번째 손가락 끝 좌표 가져오기
    double x = landmarks[8]['x'];
    double y = landmarks[8]['y'];

    // 손이 특정 영역(객체)에 가까이 있는지 확인
    if (_isNearObject(x, y)) {
      _captureAndAnalyze();
    }

    setState(() {
      _handData = "Hand at (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})";
    });
  }

  bool _isNearObject(double x, double y) {
    // 객체의 좌표와 비교하여 손이 가까이 있는지 판단하는 로직
    return (x > 0.4 && x < 0.6 && y > 0.4 && y < 0.6);
  }

  // 이 메서드가 추가된 부분입니다.
  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // 카메라 이미지 캡처
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      // Vision API로 이미지 분석
      final labels = await VisionApi.detectLabelsFromMemory(imageBytes);

      // Gemini API로 분석 결과를 기반으로 안내 생성
      final guidance = await GeminiApi().generateContent('The environment contains: $labels. What should the user do?');

      // 생성된 안내를 음성으로 제공 (Google TTS 사용)
      await GoogleTTS().speak(guidance ?? 'Unable to provide guidance.');
    } catch (e) {
      print('Error during camera feed analysis: $e');
    }
  }

  Future<void> _analyzeCameraFeed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // 이미지 캡처
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      // Vision API로 이미지 분석
      final labels = await VisionApi.detectLabelsFromMemory(imageBytes);

      // Gemini API로 분석 결과를 기반으로 안내 생성
      final guidance = await GeminiApi().generateContent('The environment contains: $labels. What should the user do?');

      // 생성된 안내를 음성으로 제공 (Google TTS 사용)
      await GoogleTTS().speak(guidance ?? 'Unable to provide guidance.');
    } catch (e) {
      print('Error during camera feed analysis: $e');
    }
  }

  Future<void> _getLocationAndMapUrl() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        return;
      }

      // 현재 위치를 가져와서 지도 URL을 업데이트합니다.
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        mapUrl = MapApiService().getMapImageUrl(position.latitude, position.longitude, 0); // 정적 지도이므로 heading(방향)을 0으로 설정
      });
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('This app requires location access to display the map. Please grant location permission in the app settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings(); // 이 옵션을 통해 사용자에게 앱 설정을 열고 권한을 부여하도록 합니다.
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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

      Future.delayed(const Duration(seconds: 1), () {
        animations.animationController.forward();
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
                    Image.asset(
                      'assets/google-gemini-icon.png', 
                      width: 50,
                      height: 50,
                    ),
                    const SizedBox(width: 10), 
                    SlideTransition(
                      position: animations.labelSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple], 
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25), 
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
                  width: 200,  // 원하는 크기로 조정
                  height: 200,  // 원하는 크기로 조정
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FutureBuilder<String>(
                      future: mapUrl,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          print('Map loading error: ${snapshot.error}');
                          return const Center(child: Text('Error loading map'));
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return Image.network(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        } else {
                          return const Center(child: Text('No map data available'));
                        }
                      },
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
  }
}
