import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EscrowPaymentScreen extends StatefulWidget {
  final String paymentUrl;

  const EscrowPaymentScreen({
    super.key,
    required this.paymentUrl,
  });

  @override
  State<EscrowPaymentScreen> createState() => _EscrowPaymentScreenState();
}

class _EscrowPaymentScreenState extends State<EscrowPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            if (url.contains('success')) {
              _handlePaymentSuccess();
            } else if (url.contains('failure') || url.contains('cancel')) {
              _handlePaymentFailure();
            }
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Error loading payment page: ${error.description}')),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentSuccess() {
    Navigator.pop(context, 'success');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment deposited successfully!')),
    );
  }

  void _handlePaymentFailure() {
    Navigator.pop(context, 'failure');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment failed or was canceled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Deposit Payment",
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0272B1),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
