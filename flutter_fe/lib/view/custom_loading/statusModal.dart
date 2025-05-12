import 'package:flutter/material.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusModal extends StatefulWidget {
  final bool isSuccess;
  final String message;
  final String? title;
  final List<Widget>? actions;
  final String? navigateToRoute;

  const StatusModal({
    super.key,
    required this.isSuccess,
    required this.message,
    this.title,
    this.actions,
    this.navigateToRoute,
  });

  static void show({
    required BuildContext context,
    required bool isSuccess,
    required String message,
    String? title,
    List<Widget>? actions,
    String? navigateToRoute,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatusModal(
        isSuccess: isSuccess,
        message: message,
        title: title,
        actions: actions,
        navigateToRoute: navigateToRoute,
      ),
    );
  }

  @override
  _StatusModalState createState() => _StatusModalState();
}

class _StatusModalState extends State<StatusModal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;

  Widget? _getRouteWidget(String? route) {
    if (route == null) return null;
    switch (route) {
      case 'otp':
        return WelcomePageViewMain();
      default:
        return null;
    }
  }

  void _handleNavigation(BuildContext context) {
    Navigator.of(context).pop();
    if (widget.isSuccess && widget.navigateToRoute != null) {
      final destinationWidget = _getRouteWidget(widget.navigateToRoute);
      if (destinationWidget != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => destinationWidget),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.title == null &&
        (widget.actions == null || widget.actions!.isEmpty)) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeOutBack),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeIn),
      );
      _controller!.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title == null &&
              (widget.actions == null || widget.actions!.isEmpty))
            Icon(
              widget.isSuccess ? Icons.check_circle : Icons.error,
              color: widget.isSuccess ? Colors.green : Colors.red,
              size: 50,
            ),
          if (widget.title == null &&
              (widget.actions == null || widget.actions!.isEmpty))
            const SizedBox(height: 10),
          Text(
            widget.title ?? (widget.isSuccess ? 'Success' : 'Error'),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isSuccess ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.actions != null && widget.actions!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.actions!,
            )
          else
            ElevatedButton(
              onPressed: () => _handleNavigation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71A4A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.title == null &&
        (widget.actions == null || widget.actions!.isEmpty)) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation!,
          child: FadeTransition(
            opacity: _fadeAnimation!,
            child: content,
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: content,
    );
  }
}
