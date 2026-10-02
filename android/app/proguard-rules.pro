# ─────────────────────────────────────────────────────────────────────────────
# Tobeque — ProGuard / R8 Rules
# These rules protect critical Flutter plugin classes from being stripped
# or obfuscated in a way that would break runtime behaviour.
# ─────────────────────────────────────────────────────────────────────────────

# ── Flutter Engine ────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── Firebase ──────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Razorpay ─────────────────────────────────────────────────────────────────
-keep class com.razorpay.** { *; }
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-optimizations !method/inlining/*

# ── OkHttp / Dio networking ───────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# ── Keep app's MainActivity ───────────────────────────────────────────────────
-keep class com.app.tobeque.** { *; }

# ── Keep annotations & serialization ─────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ── Prevent stripping of classes used by reflection ──────────────────────────
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ── Video player ──────────────────────────────────────────────────────────────
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
