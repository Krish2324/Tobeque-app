import 'package:get/get.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../home_repository.dart';
import '../models.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/shared_pref.dart';

enum MediaKind { youtube, directFile, unknown }

class HomeController extends GetxController {
  final repo = HomeRepository();

  // ── Existing state ─────────────────────────────────────────────────────────
  final loading = true.obs;
  final error = RxnString();

  final heroData     = Rxn<WpPageHero>();
  final cats         = <WcCategory>[].obs;
  final best         = <WcProduct>[].obs;
  final visibleFeaturedCount = 6.obs;
  final heroVideoUrl = RxnString();
  final showYTPlaceholder = true.obs;

  void loadMoreFeatured() {
    visibleFeaturedCount.value += 6;
  }

  // ── NEW state ──────────────────────────────────────────────────────────────
  final onSale       = <WcProduct>[].obs;   // On Sale slider
  final hotRightNow  = <WcProduct>[].obs;   // Hot Right Now cards
  final bottomBanner = Rxn<Map<String, dynamic>>(); // Promo bottom banner

  // media controllers
  VideoPlayerController? videoCtl;
  ChewieController? chewieCtl;
  YoutubePlayerController? ytCtl;

  @override
  void onInit() {
    super.onInit();
    _load();
    _checkAndPromptNotificationPermission();
  }

  Future<void> _checkAndPromptNotificationPermission() async {
    // Wait for the home screen to fully render before showing any popups
    await Future.delayed(const Duration(seconds: 3));
    final status = await Permission.notification.status;
    
    // Only prompt if they haven't been asked on the home screen yet
    if (status.isDenied) {
      final hasAsked = await SharedPrefService.getBool('has_asked_notification_home') ?? false;
      if (!hasAsked) {
        await SharedPrefService.setBool('has_asked_notification_home', true);
        await Permission.notification.request();
      }
    }
  }

  @override
  void onClose() {
    chewieCtl?.dispose();
    videoCtl?.dispose();
    ytCtl?.close();
    super.onClose();
  }

  Future<void> refreshHome() async {
    try {
      error.value = null;
      loading.value = true;
      await _load();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        repo.fetchHero(),
        repo.fetchCategories(perPage: 15),
        repo.fetchBestSellers(perPage: 12),
        repo.fetchHeroVideoUrl(),
        repo.fetchOnSaleProducts(perPage: 15),
        repo.fetchHotRightNow(perPage: 10),
        repo.fetchBottomBanner(),
      ]);

      heroData.value = results[0] as WpPageHero?;
      cats.assignAll(results[1] as List<WcCategory>);
      best.assignAll(results[2] as List<WcProduct>);

      // Handle hero video URL (extract from mobile banners if embedded)
      String? vUrl;
      final hero = heroData.value;
      if (hero != null && hero.mobileBanners.isNotEmpty) {
        final modifiableBanners = List<String>.from(hero.mobileBanners);
        final videoUrls = modifiableBanners.where((url) =>
            url.toLowerCase().endsWith('.mp4') ||
            url.toLowerCase().endsWith('.webm') ||
            url.toLowerCase().contains('.m3u8')).toList();
        if (videoUrls.isNotEmpty) {
          vUrl = videoUrls.first;
          modifiableBanners.removeWhere((url) => videoUrls.contains(url));
          hero.mobileBanners = modifiableBanners;
        }
      }
      heroVideoUrl.value = vUrl ?? results[3] as String?;

      // New sections
      onSale.assignAll(results[4] as List<WcProduct>);
      hotRightNow.assignAll(results[5] as List<WcProduct>);
      bottomBanner.value = results[6] as Map<String, dynamic>?;

      await _prepareHeroMedia();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }


 MediaKind detectUrlKind(String url) {
  final u = url.toLowerCase();
  if (u.contains('youtube.com') || u.contains('youtu.be')) return MediaKind.youtube;
  if (u.endsWith('.mp4') || u.endsWith('.webm') || u.contains('.m3u8')) return MediaKind.directFile;
  return MediaKind.unknown;
}

 String? extractYouTubeId(String url) {
  // youtu.be/<id>
  final m1 = RegExp(r'youtu\.be/([A-Za-z0-9_\-]{6,})').firstMatch(url)?.group(1);
  if (m1 != null) return m1;

  // youtube.com/watch?v=<id>
  final m2 = RegExp(r'[?&]v=([A-Za-z0-9_\-]{6,})').firstMatch(url)?.group(1);
  if (m2 != null) return m2;

  // youtube.com/embed/<id>
  final m3 = RegExp(r'youtube\.com/embed/([A-Za-z0-9_\-]{6,})').firstMatch(url)?.group(1);
  if (m3 != null) return m3;

  // youtube.com/shorts/<id>
  final m4 = RegExp(r'youtube\.com/shorts/([A-Za-z0-9_\-]{6,})').firstMatch(url)?.group(1);
  return m4;
}

Future<void> _prepareHeroMedia() async {
  final url = heroVideoUrl.value;
  if (url == null || url.isEmpty) return;

  final kind = detectUrlKind(url);

  if (kind == MediaKind.directFile) {
    // Prefer HLS (.m3u8) for adaptive HD quality if available.
    videoCtl = VideoPlayerController.networkUrl(Uri.parse(url));
    await videoCtl!.initialize();
    videoCtl!..setLooping(true)..setVolume(0)..play();

    chewieCtl = ChewieController(
      videoPlayerController: videoCtl!,
      autoInitialize: true,   // make sure textures are ready ASAP
      autoPlay: true,
      looping: true,
      showControls: false,
      allowMuting: false,
      // You can expose controls during debug to confirm the reported resolution.
    );
    return;
  }

  if (kind == MediaKind.youtube) {
    final id = extractYouTubeId(url);
    if (id == null) return;

    ytCtl = YoutubePlayerController(
      params: YoutubePlayerParams(
            mute: true,  
        // These tend to help the IFrame negotiate better quality (desktop ABR profile)
      //  desktopMode: true,
        playsInline: true,
      //  autoPlay: true,
        loop: true,                 // we manually re-play too (Shorts sometimes ignore loop)
        showControls: false,
        showFullscreenButton: false,
        enableCaption: false,
        strictRelatedVideos: true,
        origin: 'https://www.youtube-nocookie.com',
      ),
    )..loadVideoById(videoId: id);

    showYTPlaceholder.value = true;

    ytCtl!.listen((event) async {
      // Keep it playing
      if (event.playerState == PlayerState.unStarted ||
          event.playerState == PlayerState.cued ||
          event.playerState == PlayerState.paused) {
        await ytCtl!.playVideo();
      }
      // Hide placeholder once frames start showing
      if (event.playerState == PlayerState.playing ||
          event.playerState == PlayerState.buffering) {
        showYTPlaceholder.value = false;
      }
      // Loop safeguard (especially for Shorts)
      if (event.playerState == PlayerState.ended) {
        await ytCtl!.playVideo();
      }
    });

    // NOTE: YouTube IFrame chooses quality automatically. If your plugin version
    // exposes setPlaybackQuality, you can *optionally* try:
    // try { await ytCtl!.setPlaybackQuality(PlaybackQuality.hd1080); } catch (_) {}
  }
}


  /// tiny helpers for product card text
  String stripHtml(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#8377;', '₹')
      .trim();

  String decodeHtml(String s) => s.replaceAll('&#038;', '&').replaceAll('&amp;', '&');
}
