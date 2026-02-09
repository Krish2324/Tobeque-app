// lib/view/profile/sign_in_up.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _hide = true;
 bool _stay = true;
  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final c = Get.find<AuthController>();

    // If already logged in, leave immediately
    if (c.loggedIn.value) {
      Future.microtask(() => Get.back()); // or Get.offAllNamed('/root')
    }

    // React to future login changes
    ever<bool>(c.loggedIn, (ok) {
      if (ok) Get.back(); // or Get.offAllNamed('/root')
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
     if (c.loggedIn.value) {
      // returning an empty box momentarily; the ever() above will navigate away
      return const SizedBox.shrink();
    }
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
           
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text('TOBEQUE',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 22),
                      const Text(
                        'Log in or create your\nTOBEQUE MEMBERS account',
                        style: TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Get 2% cashback with every online or in-store purchase, '
                        'get rewards and access exclusive perks.',
                        style: TextStyle(color: Colors.black87, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black87, height: 1.35),
                          children: [
                            TextSpan(text: 'Join now and get your first '),
                            TextSpan(text: 'DISCOUNT', style: TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---- Error banner (sanitize HTML from server) ----
                      Obx(() {
                        final raw = c.error.value;
                        if (raw == null || raw.trim().isEmpty) return const SizedBox.shrink();
                        final linkRe = RegExp(r'<a [^>]*href="([^"]+)"[^>]*>(.*?)<\/a>', caseSensitive: false);
                        final match = linkRe.firstMatch(raw);
                        final linkText = match?.group(2) ?? 'Lost your password?';
                        final clean = raw.replaceAll(linkRe, linkText).replaceAll(RegExp(r'<[^>]+>'), '').trim();
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xffffebee),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xffef9a9a)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xffc62828)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      clean,
                                      style: const TextStyle(
                                        color: Color(0xffc62828),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => _openForgotPassword(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xffc62828),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(linkText),
                              ),
                            ],
                          ),
                        );
                      }),

                      // ---- Email + Password (row on wide, stacked on phone) ----
                      Form(
                        key: _form,
                        child: isWide
                            ? Row(children: [
                                Expanded(child: _emailField()),
                                const SizedBox(width: 12),
                                Expanded(child: _passwordField()),
                              ])
                            : Column(children: [
                                _emailField(),
                                const SizedBox(height: 12),
                                _passwordField(),
                              ]),
                      ),
                     

                      // ---- Continue (login) ----
                       Padding(
                         padding: const EdgeInsets.all(4.0),
                         child: Align(
                          alignment: AlignmentDirectional.bottomEnd,
                           child: TextButton(
                                    onPressed: () => _openForgotPassword(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xffc62828),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text("Forget Password ?"),
                                  ),
                         ),
                       ),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Obx(() {
                          final busy = c.loading.value;
                          return ElevatedButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    if (!_form.currentState!.validate()) return;
                                    await c.login(_email.text.trim(), _pass.text.trim());
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: busy
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w900)),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),

                      // ---- Create account (SIGN UP) ----
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => _openSignUp(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDBDBDB)),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),

                      const SizedBox(height: 26),
                     
                   
                  

                      const SizedBox(height: 16),
                      const Text(
                        'By logging/signing in with my social login, I agree to connect my '
                        'account in accordance with the Privacy Policy',
                        style: TextStyle(color: Colors.black54, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- fields ---
  Widget _emailField() => TextFormField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          final s = (v ?? '').trim();
          if (s.isEmpty) return 'Email address required';
          if (!s.contains('@')) return 'Enter a valid email';
          return null;
        },
        decoration: _dec(hint: 'Email address'),
      );

  Widget _passwordField() => TextFormField(
        controller: _pass,
        obscureText: _hide,
        validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
        decoration: _dec(hint: 'Password').copyWith(
          suffixIcon: IconButton(
            icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _hide = !_hide),
          ),
        ),
      );

  InputDecoration _dec({required String hint}) => InputDecoration(
        hintText: hint,
        isDense: true,
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

  void _openSignUp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const _SignUpSheet(),
    );
  }

  Future<void> _openForgotPassword(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const _ForgotSheet(),
    );
  }
}

/* --------------------------- Sign Up sheet (modal) --------------------------- */
class _SignUpSheet extends StatefulWidget {
  const _SignUpSheet();
  @override
  State<_SignUpSheet> createState() => _SignUpSheetState();
}

class _SignUpSheetState extends State<_SignUpSheet> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last  = TextEditingController();
  final _email = TextEditingController();
  bool _agree  = false;

  @override
  void dispose() {
    _first.dispose(); _last.dispose(); _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, bottom + 18),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 5,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 14),
              const Text('Create account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _first,
                    decoration: const InputDecoration(labelText: 'First name', border: OutlineInputBorder(), isDense: true),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: _last,
                    decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder(), isDense: true),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                  const Expanded(child: Text('Yes, I agree with Privacy Policy and Terms of Use'))
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() {
                  final busy = c.loading.value;
                  return ElevatedButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (!_form.currentState!.validate()) return;
                            if (!_agree) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please accept Privacy & Terms')),
                              );
                              return;
                            }
                        await c.registerWithKeys(
  first: _first.text.trim(),
  last:  _last.text.trim(),
  email: _email.text.trim(),
);

                            if (c.error.value == null) Get.back();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: busy
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create account', style: TextStyle(fontWeight: FontWeight.w900)),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------ Forgot password sheet ------------------------ */
class _ForgotSheet extends StatefulWidget {
  const _ForgotSheet();
  @override
  State<_ForgotSheet> createState() => _ForgotSheetState();
}

class _ForgotSheetState extends State<_ForgotSheet> {
  final _form = GlobalKey<FormState>();
  final _userOrEmail = TextEditingController();

  @override
  void dispose() { _userOrEmail.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, bottom + 18),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 5,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 14),
              const Text('Reset password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _userOrEmail,
                decoration: const InputDecoration(labelText: 'Email or Username', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Obx(() {
                final busy = c.loading.value;
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (!_form.currentState!.validate()) return;
                    await c.resetPasswordWithKeys(_userOrEmail.text.trim());

                            if (c.error.value == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reset link sent if account exists')),
                              );
                              Get.back();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: busy
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send link', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
