import 'dart:async';
import 'package:tobeque/view/profile/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  const CheckoutSuccessScreen({super.key, this.orderId, this.redirectUrl});
  final String? orderId;
  final String? redirectUrl;

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        if (mounted) {
          Get.off(() => const OrdersScreen()); // ✅ replace current screen
        }
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thank you')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 12),
              Text(
                'Order placed successfully!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.orderId != null) ...[
                const SizedBox(height: 6),
                Text('Order #${widget.orderId}'),
              ],
              const SizedBox(height: 20),

              // 👇 Countdown text
              Text(
                'Redirecting in $_countdown...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
              ),

              const SizedBox(height: 12),
              if (widget.redirectUrl != null && widget.redirectUrl!.isNotEmpty)
                const Text('You may be redirected for payment confirmation.'),
            ],
          ),
        ),
      ),
    );
  }
}
