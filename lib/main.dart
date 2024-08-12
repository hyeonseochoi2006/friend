import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:friend/screens/UI_system.dart';
import 'package:friend/screens/SystemInitial.dart';
import 'package:friend/start/google_splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


List<CameraDescription>? cameras;

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: UiSystem(),
    );
  }
}
