class ApiConstant {
  static const String baseUrl = 'https://backend.tobeque.com';
  static const String apiBase = '$baseUrl/api';

  // Auth endpoints
  static const String login = '$apiBase/user-auth/login';
  static const String register = '$apiBase/user-auth/register';
  static const String sendOtp = '$apiBase/user-auth/send-otp';
  static const String verifyOtp = '$apiBase/user-auth/verify-otp';
  static const String userProfile = '$apiBase/user-auth/profile';
  static const String userOrders = '$apiBase/user-auth/orders';

  // Products & Categories
  static const String products = '$apiBase/products';
  static const String categories = '$apiBase/categories/public';
  static const String banners = '$apiBase/banners';
  static const String seasonCollection = '$apiBase/season-collection';

  // Coupons & Shipping
  static const String validateCoupon = '$apiBase/coupons/validate';
  static const String calculateShipping = '$apiBase/shipping/calculate';

  // Orders & Payment
  static const String placeOrder = '$apiBase/user-auth/orders';
  static const String razorpayCreateOrder = '$apiBase/user-auth/razorpay/create-order';
  static const String razorpayVerify = '$apiBase/user-auth/razorpay/verify';

  // Image Helper
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }
}
