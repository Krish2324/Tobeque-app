// main.dart
import 'package:tobeque/view/cart/cart_events.dart';
import 'package:tobeque/view/cart/cart_service.dart';
import 'package:tobeque/view/profile/auth_repository.dart';
import 'package:tobeque/view/profile/profile_controller.dart';
import 'package:tobeque/view/root/bage_controller.dart';
import 'package:tobeque/view/splash/splash_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'package:tobeque/services/shared_pref.dart';
import 'package:tobeque/theame/light_theme.dart';

import 'package:tobeque/view/root/root_nav.dart';
import 'package:tobeque/view/onboarding/intro_screen.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // ---- register once for the whole app ----
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'Accept': 'application/json',
      // add Origin/Referer if your server needs them
      'Origin': 'https://tobeque.com',
      'Referer': 'https://tobeque.com/',
    },
  ));
  Get.put<Dio>(dio, permanent: true);

  final repo = AuthRepository(Get.find<Dio>());
  Get.put<AuthRepository>(repo, permanent: true);

  // 👇 change baseUrl if needed
  Get.put<AuthController>(AuthController(),
      permanent: true);


final seen = await SharedPrefService.getBool('onboarding_done') ?? false;
runApp(MyApp(startOnboarding: seen));
}
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await SharedPrefService.init();
//   AppDI.init();

// final seen = await SharedPrefService.getBool('onboarding_done') ?? false;
// runApp(MyApp(startOnboarding: seen));
// }




class MyApp extends StatelessWidget {
  final bool startOnboarding; // true => go to RootNav
  const MyApp({super.key, required this.startOnboarding});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tobeque',
      theme: lightTheme,
      initialBinding: AppBinding(),
      // show splash first
      home: SplashScreen(startOnboarding: startOnboarding),
    );
  }
}
class AppBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CartEvents>()) {
      Get.put(CartEvents(), permanent: true);
    }
    if (!Get.isRegistered<CartService>()) {
      Get.put(CartService(), permanent: true);
    }
    // make sure badge controller exists from launch
    if (!Get.isRegistered<CartBadgeController>(tag: 'cart-badge')) {
      Get.put(CartBadgeController(), tag: 'cart-badge', permanent: true);
    }
  }
}
