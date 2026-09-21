// lib/view/profile/sign_in_up.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// OTP Login Screen  (Phone → OTP 2-step flow)
/// ─────────────────────────────────────────────────────────────────────────────
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final c = Get.find<AuthController>();
    if (c.loggedIn.value) {
      Future.microtask(() => Get.back());
    }
    ever<bool>(c.loggedIn, (ok) {
      if (ok) Get.back();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    if (c.loggedIn.value) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOBEQUE',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Log in or create your\nTOBEQUE MEMBERS account',
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter your mobile number to receive a one-time verification code.',
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 28),

                  // Logged Out Notice Banner
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFB300),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'You are currently logged out',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Please enter your mobile number to log in again and access your account details, orders, and saved addresses.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF795548),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error / Session Expiry Banner
                  Obx(() {
                    final err = c.error.value;
                    if (err == null ||
                        err.trim().isEmpty ||
                        err.contains('401') ||
                        err.toUpperCase().contains('HTTP 401')) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffffebee),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xffef9a9a)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xffc62828), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              err,
                              style: const TextStyle(
                                color: Color(0xffc62828),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Phone number field
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: _inputDec(
                      hint: 'Mobile number (10 digits)',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 8),
                        child: Text('+91', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Send OTP button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Obx(() {
                      final busy = c.loading.value;
                      return ElevatedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final phone = _phoneCtrl.text.trim();
                                if (phone.length < 10) {
                                  c.error.value = 'Please enter a valid 10-digit mobile number';
                                  return;
                                }
                                c.error.value = null;
                                final formattedPhone = '+91$phone';
                                await c.sendOtp(formattedPhone);
                                if (!mounted) return;
                                if (c.error.value == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('OTP sent to $formattedPhone'),
                                      backgroundColor: Colors.black87,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  _openOtpSheet(context, formattedPhone);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Send OTP',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'By continuing, you agree to our Privacy Policy and Terms of Use.',
                    style: TextStyle(color: Colors.black54, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec({required String hint, Widget? prefixIcon}) => InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: prefixIcon != null
            ? Align(widthFactor: 1.0, heightFactor: 1.0, child: prefixIcon)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDBDBDB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      );

  void _openOtpSheet(BuildContext context, String phone) {
    Get.bottomSheet(
      _OtpSheet(phone: phone),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// OTP Verification Bottom Sheet
/// ─────────────────────────────────────────────────────────────────────────────
class _OtpSheet extends StatefulWidget {
  const _OtpSheet({required this.phone});
  final String phone;

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  final _otpCtrl = TextEditingController();
  bool _verifying = false;
  String? _error;
  bool _resending = false;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
        return true;
      } else {
        setState(() {
          _resendCountdown = 0;
          _canResend = true;
        });
        return false;
      }
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() => _error = 'Please enter the verification code');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    try {
      final c = Get.find<AuthController>();
      await c.verifyOtp(widget.phone, otp);
      if (c.error.value == null && c.loggedIn.value) {
        if (mounted) {
          Get.back(); // Close OTP sheet
        }
      } else {
        setState(() => _error = c.error.value ?? 'Verification failed. Please try again.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() { _resending = true; _error = null; });
    try {
      final c = Get.find<AuthController>();
      await c.sendOtp(widget.phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully!')),
        );
        _startResendTimer();
      }
    } catch (e) {
      setState(() => _error = 'Could not resend OTP. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44, height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Enter verification code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black54, fontSize: 14),
                children: [
                  const TextSpan(text: 'OTP sent to '),
                  TextSpan(
                    text: widget.phone,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // OTP field
            TextFormField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                hintStyle: const TextStyle(
                  letterSpacing: 8,
                  color: Colors.black26,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDBDBDB)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              autofocus: true,
              onFieldSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 8),

            // Error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xffc62828), fontWeight: FontWeight.w600),
                ),
              ),

            const SizedBox(height: 12),

            // Verify button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _verifying
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify & Login', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 16),

            // Resend row
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Didn't receive the code? ", style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: (_canResend && !_resending) ? _resend : null,
                    child: Text(
                      _resending
                          ? 'Sending...'
                          : (_canResend
                              ? 'Resend OTP'
                              : 'Resend in ${_resendCountdown}s'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _canResend ? Colors.black : Colors.grey,
                        decoration: _canResend ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
