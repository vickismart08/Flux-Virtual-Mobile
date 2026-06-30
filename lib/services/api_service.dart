import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://flux-virtual-backend.onrender.com';

  /// Converts any phone number to E.164 format required by Twilio.
  /// Supports all country codes — no country-specific guessing.
  /// Numbers must be entered with a country code prefix for reliable results:
  ///   +12025551234  (US)     +447911123456  (UK)
  ///   +2348012345678 (NG)    +33612345678   (FR)
  /// Short-hand formats also supported:
  ///   0012025551234 → +12025551234   (international IDD prefix)
  static String toE164(String number) {
    // Strip spaces, dashes, parentheses, dots, slashes, non-digit chars
    // but preserve a leading +
    final hasPlus = number.trimLeft().startsWith('+');
    final digits = number.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return number; // nothing to convert

    if (hasPlus) return '+$digits'; // already E.164 or close enough

    // International IDD prefix 00... → +...
    if (digits.startsWith('00')) return '+${digits.substring(2)}';

    // No country code prefix at all — prepend + and let Twilio validate.
    // Twilio will return a clear error if the number is invalid.
    return '+$digits';
  }

  static Future<String> _getToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return token ?? '';
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> initializePayment({
    required double amount,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/initializePayment'),
      headers: await _headers(),
      body: jsonEncode({'amount': (amount * 100).toInt(), 'email': email}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String reference,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verifyPayment'),
      headers: await _headers(),
      body: jsonEncode({'reference': reference}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> searchNumbers({
    required String countryCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/searchNumbers'),
      headers: await _headers(),
      body: jsonEncode({'countryCode': countryCode}),
    ).timeout(const Duration(seconds: 35));
    if (response.statusCode >= 400) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Server error ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> purchaseNumber({
    required String phoneNumber,
    required String countryCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/purchaseNumber'),
      headers: await _headers(),
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
      }),
    ).timeout(const Duration(seconds: 35));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getVoiceToken() async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/token'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String from,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/makeCall'),
          headers: await _headers(),
          body: jsonEncode({'to': toE164(to), 'from': toE164(from)}),
        )
        .timeout(const Duration(seconds: 30));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPaymentSession({
    required double amount,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/createPaymentSession'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount, 'email': email}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String from,
    required String body,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/sendSMS'),
          headers: await _headers(),
          body: jsonEncode({
            'to': toE164(to),
            'from': toE164(from),
            'body': body,
          }),
        )
        .timeout(const Duration(seconds: 30));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> renewNumber({
    required String numberId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/renewNumber'),
      headers: await _headers(),
      body: jsonEncode({'numberId': numberId}),
    );
    return jsonDecode(response.body);
  }

  static Future<void> sendWelcomeEmail() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/sendWelcomeEmail'),
        headers: await _headers(),
      );
    } catch (e) {
      // silently fail — never crash because of email
    }
  }

  static Future<void> loginNotification() async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'iPhone'
          : 'Android'; 
      await http.post(
        Uri.parse('$baseUrl/loginNotification'),
        headers: await _headers(),
        body: jsonEncode({'device': platform}),
      );
    } catch (e) {
      // silently fail
    }
  }
  static Future<Map<String, dynamic>> getPricing() async {
    final response = await http
        .get(Uri.parse('$baseUrl/pricing'))
        .timeout(const Duration(seconds: 20));
    return jsonDecode(response.body);
  }

  // ── SMS rate table (₦/message) — mirrors backend SMS_RATES ──
  static const Map<String, int> _smsRates = {
    '+1':   25,   // US/Canada
    '+44':  100,  // UK
    '+234': 120,  // Nigeria
    '+61':  130,  // Australia
    '+49':  200,  // Germany
    '+33':  150,  // France
    '+31':  150,  // Netherlands
    '+46':  150,  // Sweden
    '+27':  60,   // South Africa
    '+91':  30,   // India
    '+971': 120,  // UAE
    '+966': 120,  // Saudi Arabia
    '+55':  170,  // Brazil
    '+20':  180,  // Egypt
    '+7':   140,  // Russia
    '+82':  100,  // South Korea
    '+81':  160,  // Japan
    '+86':  100,  // China
    '+62':  220,  // Indonesia
    '+60':  140,  // Malaysia
    '+65':  100,  // Singapore
    '+92':  160,  // Pakistan
    '+880': 160,  // Bangladesh
    '+254': 180,  // Kenya
    '+233': 200,  // Ghana
    '+256': 200,  // Uganda
  };
  static const int _defaultSmsRate = 200;

  /// Returns the per-message SMS cost in NGN for a given E.164 destination.
  static int smsRateForNumber(String e164Number) {
    final prefixes = _smsRates.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final prefix in prefixes) {
      if (e164Number.startsWith(prefix)) return _smsRates[prefix]!;
    }
    return _defaultSmsRate;
  }

  // ── Call rate table (₦/min) — mirrors backend CALL_RATES ────
  static const Map<String, int> _callRates = {
    '+1':   50,
    '+44':  150,
    '+234': 250,
    '+61':  130,
    '+49':  220,
    '+33':  220,
    '+31':  200,
    '+46':  180,
    '+27':  230,
    '+91':  180,
    '+971': 320,
    '+966': 320,
    '+55':  180,
    '+20':  200,
    '+7':   210,
    '+82':  150,
    '+81':  150,
    '+86':  200,
    '+62':  200,
    '+60':  130,
    '+65':  130,
    '+92':  200,
    '+880': 200,
    '+254': 250,
    '+233': 250,
    '+256': 250,
  };
  static const int _defaultCallRate = 280;

  /// Returns the per-minute call rate in NGN for a given E.164 number.
  static int callRateForNumber(String e164Number) {
    final prefixes = _callRates.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final prefix in prefixes) {
      if (e164Number.startsWith(prefix)) return _callRates[prefix]!;
    }
    return _defaultCallRate;
  }
}
