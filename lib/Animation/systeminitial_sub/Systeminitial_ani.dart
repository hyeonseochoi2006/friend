import 'package:flutter/material.dart';

class Animations {
  late AnimationController animationController;
  late AnimationController iconAnimationController;
  late AnimationController boxAnimationController;
  late AnimationController recordRotationController;
  late Animation<double> sizeAnimation;
  late Animation<Offset> positionAnimation;
  late Animation<double> rotationAnimation;
  late Animation<Offset> finalRightAnimation;
  late Animation<double> opacityAnimation;
  late Animation<double> geminiLogoAnimation;
  late Animation<double> cameraAnimation;
  late Animation<Offset> icontalkPositionAnimation;
  late Animation<double> icontalkRotationAnimation;
  late Animation<double> icontalkOpacityAnimation;
  late Animation<double> boxOpacityAnimation;
  late Animation<Offset> boxPositionAnimation;
  late Animation<double> recordRotationAnimation;

  void initializeAnimations(TickerProvider vsync, double initialStarSize) {
    animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: vsync,
    );

    iconAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: vsync,
    );

    boxAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: vsync,
    );

    recordRotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: vsync,
    );

    sizeAnimation = Tween<double>(begin: initialStarSize, end: 35).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    positionAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.85, -1.7)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    finalRightAnimation = Tween<Offset>(begin: const Offset(-0.85, -1.7), end: const Offset(0.3, -1.7)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    rotationAnimation = Tween<double>(begin: 0.0, end: 3.14 * 2).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    geminiLogoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeIn),
      ),
    );

    cameraAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    icontalkPositionAnimation = Tween<Offset>(begin: const Offset(1.5, 0), end: const Offset(0, -0.08)).animate(
      CurvedAnimation(
        parent: iconAnimationController,
        curve: Curves.easeOut,
      ),
    );

    icontalkRotationAnimation = Tween<double>(begin: 0.0, end: 3.14 * 2).animate(
      CurvedAnimation(
        parent: iconAnimationController,
        curve: Curves.linear,
      ),
    );

    recordRotationAnimation = Tween<double>(begin: 0.0, end: 3.14 * 2).animate(
      CurvedAnimation(
        parent: recordRotationController,
        curve: Curves.linear,
      ),
    );

    icontalkOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: iconAnimationController,
        curve: Curves.easeOut,
      ),
    );

    boxOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: boxAnimationController,
        curve: Curves.easeOut,
      ),
    );

    boxPositionAnimation = Tween<Offset>(begin: const Offset(-1, -0.05), end: const Offset(0, -0.05)).animate(
      CurvedAnimation(
        parent: boxAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void dispose() {
    animationController.dispose();
    iconAnimationController.dispose();
    boxAnimationController.dispose();
    recordRotationController.dispose();
  }
}
