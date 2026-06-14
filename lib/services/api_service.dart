import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://flux-virtual-backend.onrender.com';

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
    );
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
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String from,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/makeCall'),
      headers: await _headers(),
      body: jsonEncode({'to': to, 'from': from}),
    );
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
    final response = await http.post(
      Uri.parse('$baseUrl/sendSMS'),
      headers: await _headers(),
      body: jsonEncode({'to': to, 'from': from, 'body': body}),
    );
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
}
