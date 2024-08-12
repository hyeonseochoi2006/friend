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
  const MyApp({super.key}); // Added a key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set this to false to remove the debug banner
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GoogleSplashScreen(),
    );
  }
}
