import 'package:flutter/material.dart';

class UiSystemAnimations {
  late final AnimationController animationController;
  late final AnimationController fadeInController;
  late final AnimationController containerFadeInController;
  
  late final Animation<double> opacityAnimation;
  late final Animation<double> jjjFadeInAnimation;
  late final Animation<double> containerFadeInAnimation;
  late final Animation<double> rotationAnimation;
  late final Animation<double> scaleAnimation;
  late final Animation<double> logoFadeOutAnimation;
  late final Animation<double> gradientFadeOutAnimation;
  late final Animation<Offset> iconSlideAnimation;
  late final Animation<Offset> labelSlideAnimation;

  UiSystemAnimations({required TickerProvider vsync}) {
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 6),
    );

    fadeInController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 1),
    );

    containerFadeInController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 1),
    );

    opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    jjjFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: fadeInController,
        curve: Curves.easeInOut,
      ),
    );

    containerFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: containerFadeInController,
        curve: Curves.easeInOut,
      ),
    );

    rotationAnimation = Tween<double>(begin: 0.0, end: 0.785398).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 0.75, curve: Curves.easeInOut),
      ),
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 5.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeInOut),
      ),
    );

    gradientFadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeInOut),
      ),
    );

    logoFadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 0.75, curve: Curves.easeInOut),
      ),
    );

    iconSlideAnimation = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.9, 1.0, curve: Curves.easeInOut),
      ),
    );

    labelSlideAnimation = Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.9, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  void dispose() {
    animationController.dispose();
    fadeInController.dispose();
    containerFadeInController.dispose();
  }
}
