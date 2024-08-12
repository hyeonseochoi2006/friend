import 'package:flutter/material.dart';
import 'package:friend/start/intro.dart';
import 'dart:async';
import 'dart:math';

import 'package:friend/screens/UI_system.dart'; 
class GoogleSplashScreen extends StatefulWidget {
  const GoogleSplashScreen({super.key});

  @override
  _GoogleSplashScreenState createState() => _GoogleSplashScreenState();
}

class _GoogleSplashScreenState extends State<GoogleSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
    _navigateToHome(); // _navigateToHome 함수 호출
  }

    

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 5)); // Gemini 로고를 2초 동안 보여줌
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const IntroSystem()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF001F3F), // 어두운 남색 배경
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/Google_Gemini_logo.svg.png',
              width: 200, // 너비를 200으로 설정
              height: 100, // 높이를 100으로 설정
            ),
          ),
        ),
      ),
    );
  }
}


