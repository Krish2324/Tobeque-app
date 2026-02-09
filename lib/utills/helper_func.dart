import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Normalize phone to E.164-ish (adds +<cc> if missing; defaults to India +91)
String _normalizePhone(String phone, {String defaultCountryCode = '91'}) {
  final raw = phone.trim();
  if (raw.isEmpty) return '';

  // If user already typed a +, keep it and strip non-digits.
  if (raw.startsWith('+')) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '').replaceAll('+', '');
    return '+$digits';
  }

  // Strip everything except digits, remove leading zeros
  var d = raw.replaceAll(RegExp(r'\D'), '');
  d = d.replaceFirst(RegExp(r'^0+'), '');

  // Common case: 10-digit local number -> add default country code
  if (d.length == 10 && defaultCountryCode.isNotEmpty) {
    return '+$defaultCountryCode$d';
  }

  // If looks like it already contains country code, just prefix plus
  return '+$d';
}

Future<void> launchEmail(
  String email, {
  String? subject,
  String? body,
  BuildContext? context,
}) async {
  email = email.trim();
  if (email.isEmpty) {
    _showSnack(context, 'Invalid email address');
    return;
  }

  final uri = Uri(
    scheme: 'mailto',
    path: email,
    query: [
      if (subject != null && subject.isNotEmpty)
        'subject=${Uri.encodeComponent(subject)}',
      if (body != null && body.isNotEmpty)
        'body=${Uri.encodeComponent(body)}'
    ].join('&'),
  );

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      // Fallback: copy email to clipboard
      await Clipboard.setData(ClipboardData(text: email));
      _showSnack(context, "Couldn't open email app. Email address copied: $email");
    }
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: email));
    _showSnack(context, "Couldn't open email app. Email address copied: $email");
  }
}

/// Open WhatsApp chat to [phone]. Optionally include a prefilled [message].
/// Returns true if something was launched.
Future<bool> openWhatsAppChat(
  String phone, {
  String? message,
  String defaultCountryCode = '91',
  bool preferBusiness = false,
}) async {
  final e164 = _normalizePhone(phone, defaultCountryCode: defaultCountryCode);
  if (e164.isEmpty) return false;

  final number = e164.replaceAll('+', ''); // WhatsApp expects digits only
  final textQ = (message == null || message.trim().isEmpty)
      ? ''
      : '&text=${Uri.encodeComponent(message)}';

  // Try preferred scheme first (whatsapp or whatsapp-business)
  final firstScheme = preferBusiness ? 'whatsapp-business' : 'whatsapp';
  final firstUri = Uri.parse('$firstScheme://send?phone=$number$textQ');
  if (await canLaunchUrl(firstUri)) {
    return await launchUrl(firstUri, mode: LaunchMode.externalApplication);
  }

  // Try the other scheme as a fallback
  final secondScheme = preferBusiness ? 'whatsapp' : 'whatsapp-business';
  final secondUri = Uri.parse('$secondScheme://send?phone=$number$textQ');
  if (await canLaunchUrl(secondUri)) {
    return await launchUrl(secondUri, mode: LaunchMode.externalApplication);
  }

  // Final fallback: web deep link (opens browser -> WhatsApp if available)
  final waMe = Uri.parse('https://wa.me/$number${textQ.isEmpty ? '' : '?${textQ.substring(1)}'}');
  if (await canLaunchUrl(waMe)) {
    return await launchUrl(waMe, mode: LaunchMode.externalApplication);
  }

  return false;
}






Future<void> launchPhoneCall(
  String rawNumber, {
  BuildContext? context,
}) async {
  final number = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  if (number.isEmpty) {
    _showSnack(context, 'Invalid phone number');
    return;
  }

  Future<bool> _try(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  // Primary: tel:
  final telUri = Uri(scheme: 'tel', path: number);
  if (await _try(telUri)) return;

  // iOS fallback: telprompt:
  if (!kIsWeb && Platform.isIOS) {
    final promptUri = Uri(scheme: 'telprompt', path: number);
    if (await _try(promptUri)) return;
  }

  // Last resort: copy to clipboard so user can dial manually
  await Clipboard.setData(ClipboardData(text: number));
  _showSnack(context, "Couldn't open dialer. Number copied: $number");
}




Future<void> launchWebUrl(
  String url, {
  BuildContext? context,
}) async {
  url = url.trim();
  if (url.isEmpty || !Uri.tryParse(url)!.hasAbsolutePath ) {
    _showSnack(context, 'Invalid web URL');
    return;
  }
  final uri = Uri.parse(url);

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      // Fallback: copy URL to clipboard
      await Clipboard.setData(ClipboardData(text: url));
      _showSnack(context, "Couldn't open browser. URL copied: $url");
    }
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: url));
    _showSnack(context, "Couldn't open browser. URL copied: $url");
  }
}



void _showSnack(BuildContext? ctx, String msg) {
  if (ctx == null) return;
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
}