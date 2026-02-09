import 'package:get/get.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../home_repository.dart';
import '../models.dart';

enum MediaKind { youtube, directFile, unknown }

class HomeController extends GetxController {



  
  final repo = HomeRepository();

  // state
  final loading = true.obs;
  final error = RxnString();

  final heroData = Rxn<WpPageHero>();
  final cats = <WcCategory>[].obs;
  final best = <WcProduct>[].obs;

  final heroVideoUrl = RxnString();
  final showYTPlaceholder = true.obs;

  // media controllers
  VideoPlayerController? videoCtl;
  ChewieController? chewieCtl;
  YoutubePlayerController? ytCtl;


  @override
  void onInit() {
    super.onInit();
    _load();
  }

@override
void onClose() {
  chewieCtl?.dispose();
  videoCtl?.dispose();
  ytCtl?.close(); // 👈 dispose IFrame controller too
  super.onClose();
}

Future<void> refreshHome() async {
    try {
      error.value = null;
      loading.value = true;
      await _load();            // or fetchAll()
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
      ]);

      heroData.value = results[0] as WpPageHero?;
      cats.assignAll(results[1] as List<WcCategory>);
      best.assignAll(results[2] as List<WcProduct>);
      heroVideoUrl.value = results[3] as String?;
heroVideoUrl.value = 'https://www.youtube.com/shorts/EmVHGtpCT2Y';
//https://www.youtube.com/shorts/EmVHGtpCT2Y
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
