import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A glossy, “shining wave” shimmer built on top of the `shimmer` package.
enum ShineDirection { ltr, rtl, ttb, btt, diagonal }

class ShimmerWave extends StatelessWidget {
  const ShimmerWave({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFEAEAEA),
    this.highlightColor = const Color(0xFFF6F6F6),
    this.period = const Duration(milliseconds: 4000),
    this.direction = ShineDirection.diagonal,
    this.tiltDegrees = 18,      // only used for diagonal
    this.shineWidth = 0.18,     // width of the bright band (0..1)
    this.feather = 0.12,        // soft edges around the band (0..1)
    this.enabled = true,
    this.loop,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;
  final ShineDirection direction;
  final double tiltDegrees;
  final double shineWidth;
  final double feather;
  final bool enabled;
  final int? loop;

  @override
  Widget build(BuildContext context) {
    final gradient = _buildGradient();

    return Shimmer(
      
      enabled: enabled,
      period: period,
      loop: 0,
      // `shimmer` animates the gradient across this direction. For diagonal,
      // we still pick an axis (LTR) and rotate the gradient itself below.
      direction: _mapDir(direction),
      gradient: gradient,
      child: child,
    );
  }

  LinearGradient _buildGradient() {
    // Compute a 5-stop gradient: base → softBase → highlight → softBase → base
    // centered at 0.5 with a narrow bright band.
    final half = (shineWidth.clamp(0.02, 0.9)) / 2.0;
    final f    = feather.clamp(0.0, 0.45);

    double _c(double v) => v.clamp(0.0, 1.0);

    final s1 = _c(0.5 - half - f);   // base
    final s2 = _c(0.5 - half);       // soft base just before highlight
    final s3 = 0.5;                  // bright center
    final s4 = _c(0.5 + half);       // soft base just after highlight
    final s5 = _c(0.5 + half + f);   // base

    // Slightly soften the shoulder colors (optional)
    final softBase = Color.alphaBlend(
      baseColor.withOpacity(0.7),
      highlightColor.withOpacity(0.1),
    );

    // Orientation
    Alignment begin;
    Alignment end;
    GradientTransform? rotation;

    switch (direction) {
      case ShineDirection.ltr:
        begin = Alignment.centerLeft;
        end   = Alignment.centerRight;
        break;
      case ShineDirection.rtl:
        begin = Alignment.centerRight;
        end   = Alignment.centerLeft;
        break;
      case ShineDirection.ttb:
        begin = Alignment.topCenter;
        end   = Alignment.bottomCenter;
        break;
      case ShineDirection.btt:
        begin = Alignment.bottomCenter;
        end   = Alignment.topCenter;
        break;
      case ShineDirection.diagonal:
        // We’ll sweep left→right, but rotate the gradient for a diagonal “wave”.
        begin = Alignment.centerLeft;
        end   = Alignment.centerRight;
        rotation = GradientRotation(tiltDegrees * math.pi / 180.0);
        break;
    }

    return LinearGradient(
      begin: begin,
      end: end,
      transform: rotation,
      colors: <Color>[
        baseColor,
        softBase,
        highlightColor,
        softBase,
        baseColor,
      ],
      stops: <double>[s1, s2, s3, s4, s5],
    );
  }

  ShimmerDirection _mapDir(ShineDirection d) {
    switch (d) {
      case ShineDirection.ltr: return ShimmerDirection.ltr;
      case ShineDirection.rtl: return ShimmerDirection.rtl;
      case ShineDirection.ttb: return ShimmerDirection.ttb;
      case ShineDirection.btt: return ShimmerDirection.btt;
      case ShineDirection.diagonal:
        // The package has no diagonal enum; we rotate the gradient instead.
        return ShimmerDirection.ltr;
    }
  }

  /// Handy presets
  factory ShimmerWave.box({
    Key? key,
    double? width,
    double? height,
    BorderRadius? radius,
    Color base = const Color(0xFFEAEAEA),
    Color hi   = const Color(0xFFF6F6F6),
    double shineWidth = 0.18,
    double feather = 0.12,
  }) {
    return ShimmerWave(
      key: key,
      baseColor: base,
      highlightColor: hi,
      shineWidth: shineWidth,
      feather: feather,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  factory ShimmerWave.circle({
    Key? key,
    double size = 56,
    Color base = const Color(0xFFEAEAEA),
    Color hi   = const Color(0xFFF6F6F6),
    double shineWidth = 0.18,
    double feather = 0.12,
  }) {
    return ShimmerWave(
      key: key,
      baseColor: base,
      highlightColor: hi,
      shineWidth: shineWidth,
      feather: feather,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}
