import 'package:flutter/foundation.dart';

class CartBus {
  CartBus._();
  static final CartBus I = CartBus._();

  /// increases when the cart changes anywhere in the app
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  void bump() => version.value++;
}
