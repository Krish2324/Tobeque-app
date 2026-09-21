// lib/view/intro/intro_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:tobeque/services/shared_pref.dart';
import 'package:tobeque/view/root/root_nav.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _page = PageController();
  int _index = 0;
  static const int _slideCount = 3;
bool _askedDialog = false; // avoid re-prompting on swipe back/forth

// REMOVE _askForNotification() and its dialog, and ADD this instead:
Future<void> _requestNotification() async {
  // If already granted, go right away
  final before = await Permission.notification.status;
  if (before.isGranted) {
    await _proceed(granted: true);
    return;
  }

  // Ask OS once (no custom dialog)
  final st = await Permission.notification.request();

  if (st.isGranted || st.isLimited || st.isProvisional) {
    await _proceed(granted: true);
  } else if (st.isPermanentlyDenied) {
    // Optional: show a settings hint; or skip straight to _proceed(false)
    _showGoToSettings();
  } else {
    await _proceed(granted: false);
  }
}


Future<void> _proceed({required bool granted}) async {
  if (granted) {
    setState(() => _showAllSet = true);
    _ac.forward();
    await Future.delayed(const Duration(milliseconds: 800));
  }
  await SharedPrefService.setBool('onboarding_done', true);
  if (!mounted) return;
  Get.offAll(() => const RootNav());
}

void _showGoToSettings() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Notifications disabled'),
      content: const Text('You can enable notifications any time in App Settings.'),
      actions: [
        TextButton(
          onPressed: () { Navigator.pop(context); _proceed(granted: false); },
          child: const Text('Continue'),
        ),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); openAppSettings(); },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}

  // Bottom-up entrance for “All set!” panel
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<Offset> _slide = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
      .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

  bool _checking = false;
  bool _showAllSet = false;

  ImageProvider _imageForIndex(int i) {
    if (i == 2) {
      return const AssetImage('assets/OnBoarding-4.jpg');
    } else if (i == 1) {
      return const AssetImage('assets/OnBoarding-2.jpg');
    } else {
      return const AssetImage('assets/OnBoarding-1.jpg');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _precache(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ac.dispose();
    _page.dispose();
    super.dispose();
  }

  // When returning from settings, re-verify on the last page
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _index == 2) {
      _verifyAndProceed();
    }
  }

  Future<void> _precache(int page) async {
    if (!mounted) return;
    final next = min(page + 1, _slideCount - 1);
    await precacheImage(_imageForIndex(next), context);
  }

  Future<void> _openSettings() async => openAppSettings();

  Future<void> _verifyAndProceed() async {
    setState(() => _checking = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() => _checking = false);

    if (status.isGranted) {
      setState(() => _showAllSet = true);
      _ac.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      await SharedPrefService.setBool('onboarding_done', true);
      if (!mounted) return;
      Get.offAll(() => const RootNav());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable notifications in Settings.')),
      );
    }
  }

  // Slide builder (accepts ImageProvider so it works for asset or network)
  Widget _pageSlide({
    required ImageProvider image,
    required String title,
    required String subtitle,
    bool showCta = false,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed cover image
        Image(
          image: image,
          fit: BoxFit.cover,
          errorBuilder: (_, error, ___) {
            debugPrint('Error loading intro slide image: $error');
            return Container(color: const Color(0xFF111111));
          },
        ),

        // Vignette overlay for readability (reduced shading)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(.10), // Very light at top
                Colors.transparent,
                Colors.black.withOpacity(.75), // Enough for white text readability
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.40, 1.0],
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 20, end: 0),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (_, dy, child) => Transform.translate(
                    offset: Offset(0, dy),
                    child: child,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.04,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
if (showCta)
  Column(
    children: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _proceed(granted: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Don't allow", style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _requestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Allow notifications',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .3)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _checking
            ? const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: LinearProgressIndicator(minHeight: 6),
              )
            : const SizedBox(height: 6),
      ),
      TextButton(
        onPressed: () async {
          await SharedPrefService.setBool('onboarding_done', true);
          if (!mounted) return;
          Get.offAll(() => const RootNav());
        },
        child: const Text('Skip for now',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
      ),
    ],
  ),
                const SizedBox(height: 45), // Push content above the page indicator dots (reduced space)
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _pageSlide(
        image: _imageForIndex(0),
        title: "Define Your Aesthetic",
        subtitle: "Unlock exclusive styles you won't find anywhere else. Ready to stand out?",
      ),
      _pageSlide(
        image: _imageForIndex(1),
        title: "Elevate Your Wardrobe",
        subtitle: "Discover hand-picked collections that turn every day into a runway.",
      ),
      _pageSlide(
        image: _imageForIndex(2),
        title: "Never Miss a Drop",
        subtitle: "Enable notifications for secret drops, flash sales, and order updates.",
        showCta: true,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: PageView.builder(
              controller: _page,
              itemCount: slides.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _precache(i);
              },
              itemBuilder: (_, i) => slides[i],
            ),
          ),

          // --- sliding dots ---
          if (_index != _slideCount - 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: SafeArea(
                top: false,
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _page,
                    count: _slideCount,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Colors.white,
                      dotColor: Colors.white38,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                      expansionFactor: 3,
                    ),
                    onDotClicked: (i) => _page.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
              ),
            ),

          // “All set!” overlay (bottom-up)
          if (_showAllSet)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "All set!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .3,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Enjoy the Tobeque experience",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Next FAB (hidden on last slide)
      floatingActionButton: _index == _slideCount - 1
          ? null
          : FloatingActionButton(
              onPressed: () => _page.nextPage(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeInOut,
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.arrow_forward),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }
}
