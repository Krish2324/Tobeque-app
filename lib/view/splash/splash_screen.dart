import 'package:tobeque/view/onboarding/intro_screen.dart';
import 'package:tobeque/view/root/root_nav.dart';
import 'package:tobeque/view/wishlist/wishlist_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final bool startOnboarding;
  const SplashScreen({super.key, required this.startOnboarding});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // init video
    _controller = VideoPlayerController.asset("assets/splash.mp4")
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    // preload services & go next after 7 sec
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Get.put(WishlistService());
      await Future.delayed(const Duration(seconds: 7));
      if (!mounted) return;

      if (widget.startOnboarding) {
        Get.offAll(() => const RootNav());
      } else {
        Get.offAll(() => const IntroScreen());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : SizedBox(),
      ),
    );
  }
}
