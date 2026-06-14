import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/services/api_service.dart';

class PaystackWebView extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final bool isSession;

  const PaystackWebView({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    this.isSession = false,
  });

  @override
  State<PaystackWebView> createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<PaystackWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
  if (request.url.contains('paystack.co/close') ||
      request.url.contains('paystack.co/cancel') ||
      request.url.contains('callbackUrl') ||
      request.url.contains('callback') ||
      request.url.contains('success') ||
      request.url.contains('cancelled')) {
    _verifyPayment();
    return NavigationDecision.prevent;
  }
  return NavigationDecision.navigate;
},
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  Future<void> _verifyPayment() async {
    setState(() => _isVerifying = true);

    try {
      final result =
          await ApiService.verifyPayment(reference: widget.reference);

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pop(context, true); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '\$${result['amount'].toStringAsFixed(2)} added to your balance!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          Navigator.pop(context, false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Payment failed'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Add Credit'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context, false),
      ),
      
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : _verifyPayment,
          child: const Text(
            'Verify',
            style: TextStyle(
              color: AppColors.softOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: Stack(
      children: [
        WebViewWidget(controller: _controller),

        if (_isLoading)
          const Center(child: CircularProgressIndicator()),

        if (_isVerifying)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.warmBeige,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Verifying payment...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
}