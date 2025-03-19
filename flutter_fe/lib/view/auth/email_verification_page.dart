import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';

class EmailVerificationPage extends StatefulWidget {
  final String token;
  final String email;

  const EmailVerificationPage({
    Key? key,
    required this.token,
    required this.email,
  }) : super(key: key);

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final ProfileController _controller = ProfileController();
  bool _isLoading = true;
  String _message = '';
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    try {
      final userId = await _controller.verifyEmail(
        context,
        widget.token,
        widget.email,
      );

      setState(() {
        _isLoading = false;
        _isVerified = true;
        _message = 'Email verified successfully!';
      });

      // Navigate to user navigation after short delay
      if (!mounted) return;
      Future.delayed(const Duration(seconds: 2), () {
        debugPrint('User ID from the user: $userId');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'Failed to verify email. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text('Verifying your email...'),
              ] else ...[
                Icon(
                  _isVerified ? Icons.check_circle : Icons.error,
                  color: _isVerified ? Colors.green : Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  _message,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
