// lib/view/refund/refund_request_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';
import 'package:tobeque/services/shared_pref.dart';

class RefundRequestPage extends StatefulWidget {
  const RefundRequestPage({super.key});

  @override
  State<RefundRequestPage> createState() => _RefundRequestPageState();
}

class _RefundRequestPageState extends State<RefundRequestPage> {
  final _formKey   = GlobalKey<FormState>();
  final _orderCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  String? _selectedReason;
  bool _loading = false;
  bool _sent    = false;

  static const _reasons = [
    'Wrong size received',
    'Wrong product received',
    'Defective/damaged product',
    'Product not as described',
    'Changed my mind',
    'Quality not as expected',
    'Other',
  ];

  @override
  void dispose() {
    _orderCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final token = await SharedPrefService.getToken();
      final dio   = DioClient.build();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';

      await dio.post(ApiConstant.refundRequests, data: {
        'orderId': _orderCtrl.text.trim(),
        'reason':  _selectedReason ?? _reasonCtrl.text.trim(),
        'details': _reasonCtrl.text.trim(),
      });
      setState(() { _loading = false; _sent = true; });
    } on DioException catch (e) {
      setState(() => _loading = false);
      final msg = (e.response?.data is Map ? e.response!.data['message'] : null) ?? 'Failed to submit request.';
      _showSnack(msg.toString(), error: true);
    } catch (_) {
      setState(() => _loading = false);
      _showSnack('Something went wrong. Please try again.', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
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
              'RETURN & REFUND',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 3.0, color: Colors.black),
            ),
            Text(
              'Submit a refund request',
              style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: _sent ? _SuccessView() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Policy notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFF6F6F5)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF0D0D0D)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We offer a 7-day return policy on all items. Products must be unworn and in original packaging. Refunds are processed within 5–7 business days.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B), height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Order ID
            _FieldLabel('Order ID'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orderCtrl,
              decoration: _fieldDecor('e.g. ORD-2025-XXXXX'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Please enter your order ID' : null,
            ),
            const SizedBox(height: 20),

            // Reason dropdown
            _FieldLabel('Reason for Return'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selectedReason = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Please select a reason' : null,
              decoration: _fieldDecor('Select reason'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF0D0D0D)),
              iconEnabledColor: const Color(0xFF0D0D0D),
              dropdownColor: Colors.white,
            ),
            const SizedBox(height: 20),

            // Additional details
            _FieldLabel('Additional Details (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 4,
              decoration: _fieldDecor('Describe the issue in detail...'),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D0D0D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SUBMIT REQUEST', style: TextStyle(letterSpacing: 2.5, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _FieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: 0.5),
    );
  }

  InputDecoration _fieldDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF6F6F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: Color(0xFF0D0D0D), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: Color(0xFFE53935))),
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
              width: 72, height: 72,
              decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 36, color: Color(0xFF0D0D0D)),
            ),
            const SizedBox(height: 20),
            const Text('Request Submitted!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D))),
            const SizedBox(height: 10),
            const Text(
              'Your refund request has been received. Our team will process it within 2–3 business days and reach out to you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.6),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: Get.back,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: const BoxDecoration(color: Color(0xFF0D0D0D)),
                child: const Text('GO BACK',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 2.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
