import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarUtil {
  static void showCustomSnackBar({
    required String title,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
SnackPosition snakePossition =SnackPosition.BOTTOM,
    VoidCallback? onPressed,
  }) {
     Get.showSnackbar(
  GetSnackBar(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    backgroundColor: isError ? Colors.red[400]! : Colors.green[400]!,
    icon: Icon(
      isError ? Icons.error_outline : Icons.check_circle_outline,
      size: 20,
      color: Colors.white,
    ),
    duration: duration,
    borderRadius: 0,
    snackPosition: snakePossition,
    snackStyle: SnackStyle.FLOATING,
    onTap: onPressed != null ? (_) => onPressed() : null,
    
    titleText: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    messageText: Text(
      message,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.white,
      ),
    ),
  ),
);

  }
}