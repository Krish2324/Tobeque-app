// lib/view/contact/contact_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey   = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _msgFocus   = FocusNode();

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _msgCtrl   = TextEditingController();

  bool _loading = false;
  bool _sent    = false;
  bool _fetchingSettings = true;

  String _email = 'care@tobeque.com';
  String _phone = '+91 84470 00200';
  String _whatsapp = '+918447000200';
  String _officeAddress = '';
  String _businessHours = '';

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final dio = DioClient.build();
      final res = await dio.get('${ApiConstant.apiBase}/contact/settings');
      if (res.data is Map && res.data['data'] != null) {
        final data = res.data['data'] as Map;
        setState(() {
          if ((data['email'] ?? '').toString().isNotEmpty) _email = data['email'].toString();
          if ((data['phone'] ?? '').toString().isNotEmpty) _phone = data['phone'].toString();
          if ((data['whatsapp'] ?? '').toString().isNotEmpty) _whatsapp = data['whatsapp'].toString();
          if ((data['officeAddress'] ?? '').toString().isNotEmpty) _officeAddress = data['officeAddress'].toString();
          if ((data['businessHours'] ?? '').toString().isNotEmpty) _businessHours = data['businessHours'].toString();
        });
      }
    } catch (_) {
      // Fallback to default branding info if API call fails
    } finally {
      if (mounted) setState(() => _fetchingSettings = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final dio = DioClient.build();
      await dio.post('${ApiConstant.apiBase}/contact/submit', data: {
        'name':    _nameCtrl.text.trim(),
        'email':   _emailCtrl.text.trim(),
        'phone':   _phoneCtrl.text.trim(),
        'message': _msgCtrl.text.trim(),
      });
      setState(() { _loading = false; _sent = true; });
    } on DioException catch (e) {
      setState(() => _loading = false);
      final msg = (e.response?.data is Map ? e.response!.data['message'] : null) ?? 'Something went wrong. Please try again.';
      _showError(msg.toString());
    } catch (_) {
      setState(() => _loading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          onPressed: Get.back,
        ),
        title: const Column(
          children: [
            Text(
              'CONTACT US',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 3.0, color: Colors.black),
            ),
            Text(
              "We'd love to hear from you",
              style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: _sent ? _SuccessView() : _FormView(
        formKey: _formKey,
        nameCtrl: _nameCtrl,
        emailCtrl: _emailCtrl,
        phoneCtrl: _phoneCtrl,
        msgCtrl: _msgCtrl,
        nameFocus: _nameFocus,
        emailFocus: _emailFocus,
        phoneFocus: _phoneFocus,
        msgFocus: _msgFocus,
        loading: _loading,
        fetchingSettings: _fetchingSettings,
        email: _email,
        phone: _phone,
        whatsapp: _whatsapp,
        officeAddress: _officeAddress,
        businessHours: _businessHours,
        onSubmit: _submit,
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey, required this.nameCtrl, required this.emailCtrl,
    required this.phoneCtrl, required this.msgCtrl, required this.nameFocus,
    required this.emailFocus, required this.phoneFocus, required this.msgFocus,
    required this.loading, required this.fetchingSettings, required this.email,
    required this.phone, required this.whatsapp, required this.officeAddress,
    required this.businessHours, required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl, msgCtrl;
  final FocusNode nameFocus, emailFocus, phoneFocus, msgFocus;
  final bool loading, fetchingSettings;
  final String email, phone, whatsapp, officeAddress, businessHours;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reach out section
            const Text(
              'Get in touch',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, letterSpacing: -0.5, color: Color(0xFF0D0D0D)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fill in the form and our team will get back to you within 24 hours.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.55),
            ),
            const SizedBox(height: 28),

            // Dynamic contact info from admin
            if (fetchingSettings)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                ),
              )
            else ...[
              if (email.isNotEmpty)
                _ContactInfoRow(icon: Icons.email_outlined, label: 'EMAIL', value: email),
              if (phone.isNotEmpty || whatsapp.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ContactInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'WHATSAPP / PHONE',
                  value: whatsapp.isNotEmpty ? whatsapp : phone,
                ),
              ],
              if (officeAddress.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ContactInfoRow(icon: Icons.location_on_outlined, label: 'OFFICE ADDRESS', value: officeAddress),
              ],
              if (businessHours.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ContactInfoRow(icon: Icons.access_time, label: 'BUSINESS HOURS', value: businessHours),
              ],
            ],

            const SizedBox(height: 28),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 28),

            // Form fields
            _FormField(
              controller: nameCtrl,
              focusNode: nameFocus,
              nextFocus: emailFocus,
              label: 'Full Name',
              hint: 'Your name',
              icon: Icons.person_outline,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),

            _FormField(
              controller: emailCtrl,
              focusNode: emailFocus,
              nextFocus: phoneFocus,
              label: 'Email Address',
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'Please enter your email';
                if (!GetUtils.isEmail(v!.trim())) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _FormField(
              controller: phoneCtrl,
              focusNode: phoneFocus,
              nextFocus: msgFocus,
              label: 'Phone Number (optional)',
              hint: '+91 XXXXX XXXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            _FormField(
              controller: msgCtrl,
              focusNode: msgFocus,
              label: 'Message',
              hint: 'How can we help you?',
              icon: Icons.message_outlined,
              maxLines: 5,
              textInputAction: TextInputAction.done,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please enter your message' : null,
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D0D0D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  disabledBackgroundColor: const Color(0xFF0D0D0D).withOpacity(0.6),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SEND MESSAGE',
                        style: TextStyle(letterSpacing: 2.5, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.nextFocus,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: (_) {
            if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 0),
            filled: true,
            fillColor: const Color(0xFFF6F6F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: Color(0xFF0D0D0D), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  const _ContactInfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          color: const Color(0xFFF6F6F5),
          child: Icon(icon, size: 16, color: const Color(0xFF0D0D0D)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 36, color: Color(0xFF0D0D0D)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Message Sent!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D)),
            ),
            const SizedBox(height: 10),
            const Text(
              "Thanks for reaching out. We'll get back to you within 24 hours.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B), height: 1.6),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: Get.back,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: const BoxDecoration(color: Color(0xFF0D0D0D)),
                child: const Text(
                  'GO BACK',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 2.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
