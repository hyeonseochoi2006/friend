import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:friend/servers/vision_api.dart';

class CameraService {
  CameraController? _controller;
  bool _isDetecting = false;

  CameraController? get controller => _controller;

  Future<void> initializeCamerasystem() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<String> captureAndDetectLabels() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDetecting) {
      return '';
    }
    
    _isDetecting = true;
    try {
      final image = await _controller!.takePicture();
      final imageBytes = await image.readAsBytes();
      final labels = await VisionApi.detectLabelsFromMemory(imageBytes);
      _isDetecting = false;
      return labels;
    } catch (e) {
      print('Error detecting labels: $e');
      _isDetecting = false;
      return '';
    }
  }

  void dispose() {
    _controller?.dispose();
  }
}
