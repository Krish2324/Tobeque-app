// lib/constants/api_constants.dart
class ApiConstant {
  static const String baseUrl = 'https://backend.tobeque.com';
  static const String apiBase = '$baseUrl/api';

  // ── Auth (OTP-based user auth) ──────────────────────────────────────────────
  static const String login                = '$apiBase/user-auth/login';
  static const String register             = '$apiBase/user-auth/register';
  static const String sendOtp              = '$apiBase/user-auth/send-otp';
  static const String verifyOtp            = '$apiBase/user-auth/verify-otp';
  static const String userProfile          = '$apiBase/user-auth/profile';
  static const String userOrders           = '$apiBase/user-auth/orders';

  // ── Products & Categories ───────────────────────────────────────────────────
  static const String products             = '$apiBase/products';
  static const String categories           = '$apiBase/categories/public';
  static const String brands               = '$apiBase/categories/brands/all';

  // ── Banners & Collections ───────────────────────────────────────────────────
  static const String banners              = '$apiBase/banners';
  static const String seasonCollection     = '$apiBase/season-collection';

  // ── Coupons & Shipping ──────────────────────────────────────────────────────
  static const String validateCoupon       = '$apiBase/user-auth/validate-coupon';
  static const String calculateShipping    = '$apiBase/shipping/calculate';

  // ── Orders & Payment ────────────────────────────────────────────────────────
  static const String placeOrder           = '$apiBase/user-auth/orders';
  static const String razorpayCreateOrder  = '$apiBase/user-auth/razorpay/create-order';
  static const String razorpayVerify       = '$apiBase/user-auth/razorpay/verify';
  static const String razorpayConfig       = '$apiBase/user-auth/razorpay/config';

  // ── Content ─────────────────────────────────────────────────────────────────
  static const String blogs                = '$apiBase/blogs';
  static const String communityStyles      = '$apiBase/community-styles/public';
  static const String faqs                 = '$apiBase/faqs';
  static const String aboutUs              = '$apiBase/about-us';
  static const String contact              = '$apiBase/contact';
  static const String subscribers          = '$apiBase/subscribers';
  static const String refundRequests       = '$apiBase/refund-requests';
  static const String jobPostings          = '$apiBase/job-postings';
  static const String jobApplications      = '$apiBase/job-applications';
  static const String inquiries            = '$apiBase/inquiries';
  static const String publicSettings       = '$apiBase/settings/public';

  // ── Image Helper ────────────────────────────────────────────────────────────
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    var url = path.trim();
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    if (url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }
}
