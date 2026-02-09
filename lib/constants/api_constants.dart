class ApiConstant {

  
  static const String baseUrl = 'https://tobeque.com';
  static const String restPrefix = 'wp-json';

  // WordPress Core REST
  static String wp(String path) => '$baseUrl/$restPrefix/wp/v2/$path';

  // WooCommerce Store API (no auth for public catalog)
  static String wcStore(String path) => '$baseUrl/$restPrefix/wc/store/v1/$path';

  // WooCommerce REST v3 (requires keys; for admin-like ops)
  static String wcV3(String path) => '$baseUrl/$restPrefix/wc/v3/$path';

  // If you need CK/CS (server should be HTTPS)
  static const consumerKey = 'ck_f826ac5930933a42627eb47f74a0cec91d938f5b';
  static const consumerSecret = 'cs_0a8e1e294651634cc544f488d94f62c7bd87abab';
}

